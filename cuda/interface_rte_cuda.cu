#include <openacc.h>
#include <cstdio>
#include <exception>

#include "Types.h"

// CvH: zero_array should move to rte kernels.
#include "rrtmgp_kernel_launcher_cuda.h"
#include "rte_kernel_launcher_cuda.h"
#include "optical_props_kernel_launcher_cuda.h"
#include "fluxes_kernel_launcher_cuda.h"


template<typename T> T* acc_to_cuda(T* ptr) { return static_cast<T*>(acc_deviceptr(ptr)); }


extern "C"
{
    // SHORTWAVE SOLVERS
    void rte_sw_solver_noscat(
            int* ncol, int* nlay, int* ngpt, Bool* top_at_1,
            Float* tau,
            Float* mu0,
            Float* inc_flux_dir,
            Float* flux_dir)
    {
        throw std::runtime_error("rte_sw_solver_noscat not implemented in CUDA!");
    }


    void rte_sw_solver_2stream(
            int* ncol, int* nlay, int* ngpt, Bool* top_at_1,
            Float* tau, Float* ssa, Float* g,
            Float* mu0,
            Float* sfc_alb_dir, Float* sfc_alb_dif,
            Float* inc_flux_dir,
            Float* flux_up, Float* flux_dn, Float* flux_dir,
            Bool* has_dif_bc, Float* inc_flux_dif,
            Bool* do_broadband, Float* flux_up_loc, Float* flux_dn_loc, Float* flux_dir_loc)
    {
        // CvH: our CUDA kernels did not implement the do broadband due to negligible performance gains.
        if (*do_broadband)
        {
            printf("CvH: sw_solver_2stream broadband CUDA\n");
            Float* gpt_flux_up  = Tools_gpu::allocate_gpu<Float>((*ncol) * (*nlay+1) * (*ngpt));
            Float* gpt_flux_dn  = Tools_gpu::allocate_gpu<Float>((*ncol) * (*nlay+1) * (*ngpt));
            Float* gpt_flux_dir = Tools_gpu::allocate_gpu<Float>((*ncol) * (*nlay+1) * (*ngpt));

            rte_kernel_launcher_cuda::sw_solver_2stream(
                    *ncol, *nlay, *ngpt, *top_at_1,
                    acc_to_cuda(tau), acc_to_cuda(ssa), acc_to_cuda(g),
                    acc_to_cuda(mu0),
                    acc_to_cuda(sfc_alb_dir), acc_to_cuda(sfc_alb_dif),
                    acc_to_cuda(inc_flux_dir),
                    gpt_flux_up, gpt_flux_dn, gpt_flux_dir,
                    *has_dif_bc, acc_to_cuda(inc_flux_dif),
                    *do_broadband, acc_to_cuda(flux_up_loc), acc_to_cuda(flux_dn_loc), acc_to_cuda(flux_dir_loc));

            fluxes_kernel_launcher_cuda::sum_broadband(
                    *ncol, (*nlay+1), *ngpt,
                    gpt_flux_up, acc_to_cuda(flux_up_loc));

            fluxes_kernel_launcher_cuda::sum_broadband(
                    *ncol, (*nlay+1), *ngpt,
                    gpt_flux_dn, acc_to_cuda(flux_dn_loc));

            Tools_gpu::free_gpu<Float>(gpt_flux_up);
            Tools_gpu::free_gpu<Float>(gpt_flux_dn);
            Tools_gpu::free_gpu<Float>(gpt_flux_dir);
        }
        else
        {
            printf("CvH: sw_solver_2stream gpt CUDA (SHOULD NOT WORK WELL) \n");
            rte_kernel_launcher_cuda::sw_solver_2stream(
                    *ncol, *nlay, *ngpt, *top_at_1,
                    acc_to_cuda(tau), acc_to_cuda(ssa), acc_to_cuda(g),
                    acc_to_cuda(mu0),
                    acc_to_cuda(sfc_alb_dir), acc_to_cuda(sfc_alb_dif),
                    acc_to_cuda(inc_flux_dir),
                    acc_to_cuda(flux_up), acc_to_cuda(flux_dn), acc_to_cuda(flux_dir),
                    *has_dif_bc, acc_to_cuda(inc_flux_dif),
                    *do_broadband, acc_to_cuda(flux_up_loc), acc_to_cuda(flux_dn_loc), acc_to_cuda(flux_dir_loc));
        }
    }

    // void lw_solver_noscat_gaussquad(
    void rte_lw_solver_noscat(
            int* ncol, int* nlay, int* ngpt, Bool* top_at_1, int* nmus,
            Float* secants, Float* weights,
            Float* tau, Float* lay_source,
            Float* lev_source_inc, Float* lev_source_dec,
            Float* sfc_emis, Float* sfc_src,
            Float* inc_flux,
            Float* flux_up, Float* flux_dn,
            Bool* do_broadband, Float* flux_up_loc, Float* flux_dn_loc,
            Bool* do_jacobians, Float* sfc_src_jac, Float* flux_up_jac)
    {
        printf("CvH: lw_solver_noscat CUDA\n");

        // CVH: TMP SOLUTION
        Float* weights_gpu = Tools_gpu::allocate_gpu<Float>( (*nmus) );
        acc_memcpy_to_device(weights_gpu, weights, *nmus * sizeof(Float));

        Float* sfc_src_jac_dummy = Tools_gpu::allocate_gpu<Float>( (*ngpt) * (*ncol) );
        if (*do_jacobians != 0)
        {
            rte_kernel_launcher_cuda::lw_solver_noscat_gaussquad(
                    *ncol, *nlay, *ngpt, *top_at_1, *nmus,
                    // acc_to_cuda(secants), acc_to_cuda(weights),
                    acc_to_cuda(secants), weights_gpu,
                    acc_to_cuda(tau), acc_to_cuda(lay_source),
                    acc_to_cuda(lev_source_inc), acc_to_cuda(lev_source_dec),
                    acc_to_cuda(sfc_emis), acc_to_cuda(sfc_src),
                    acc_to_cuda(inc_flux),
                    acc_to_cuda(flux_up), acc_to_cuda(flux_dn),
                    *do_broadband, acc_to_cuda(flux_up_loc), acc_to_cuda(flux_dn_loc),
                    *do_jacobians, acc_to_cuda(sfc_src_jac), acc_to_cuda(flux_up_jac));
        }
        else
        {
            Float* sfc_src_jac_dummy = Tools_gpu::allocate_gpu<Float>( (*ngpt) * (*ncol) );
            Float* flux_up_jac_dummy = Tools_gpu::allocate_gpu<Float>( (*ngpt) * ( (*nlay) + 1 ) * (*ncol) );
            
            rte_kernel_launcher_cuda::lw_solver_noscat_gaussquad(
                    *ncol, *nlay, *ngpt, *top_at_1, *nmus,
                    // acc_to_cuda(secants), acc_to_cuda(weights),
                    acc_to_cuda(secants), weights_gpu,
                    acc_to_cuda(tau), acc_to_cuda(lay_source),
                    acc_to_cuda(lev_source_inc), acc_to_cuda(lev_source_dec),
                    acc_to_cuda(sfc_emis), acc_to_cuda(sfc_src),
                    acc_to_cuda(inc_flux),
                    acc_to_cuda(flux_up), acc_to_cuda(flux_dn),
                    *do_broadband, acc_to_cuda(flux_up_loc), acc_to_cuda(flux_dn_loc),
                    *do_jacobians, sfc_src_jac_dummy, flux_up_jac_dummy);

            Tools_gpu::free_gpu(sfc_src_jac_dummy);
            Tools_gpu::free_gpu(flux_up_jac_dummy);
        }

        Tools_gpu::free_gpu(weights_gpu);
    }


    void rte_lw_solver_2stream(
            int* ncol, int* nlay, int* ngpt, Bool* top_at_1,
            Float* tau, Float* ssa, Float* g,
            Float* lay_source, Float* lev_source_inc, Float* lev_source_dec,
            Float* sfc_emis, Float* sfc_src,
            Float* inc_flux,
            Float* flux_up, Float* flux_dn)
    {
        throw std::runtime_error("rte_lw_solver_2stream not implemented in CUDA!");
    }


    // void lw_secants_array(
    //         const int ncol, const int ngpt, const int n_quad_angs, const int max_gauss_pts,
    //         const Float* Gauss_Ds, Float* secants);


    // OPTICAL PROPS - INCREMENT
    void rte_increment_1scalar_by_1scalar(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, const Float* tau_in)
    {
        printf("CvH: rte_increment_1scalar_by_1scalar CUDA\n");
        optical_props_kernel_launcher_cuda::increment_1scalar_by_1scalar(
                *ncol, *nlay, *ngpt,
                tau_inout, tau_in);
    }


    void rte_increment_1scalar_by_2stream(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout,
            Float* tau_in, Float* ssa_in)
    {
        throw std::runtime_error("increment_1scalar_by_2stream is not implemented in CUDA");
    }


    void rte_increment_1scalar_by_nstream(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout,
            Float* tau_in, Float* ssa_in)
    {
        throw std::runtime_error("increment_1scalar_by_nstream is not implemented in CUDA");
    }


    void rte_increment_2stream_by_1scalar(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout,
            Float* tau_in)
    {
        throw std::runtime_error("increment_2stream_by_1scalar is not implemented in CUDA");
    }


    void rte_increment_2stream_by_2stream(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout, Float* g_inout,
            const Float* tau_in, const Float* ssa_in, const Float* g_in)
    {
        printf("CvH: rte_increment_2stream_by_2stream CUDA\n");
        optical_props_kernel_launcher_cuda::increment_2stream_by_2stream(
                *ncol, *nlay, *ngpt,
                tau_inout, ssa_inout, g_inout,
                tau_in, ssa_in, g_in);
    }


    void rte_increment_2stream_by_nstream(
            int* ncol, int* nlay, int* ngpt, int* nmom,
            Float* tau_inout, Float* ssa_inout, Float* g_inout,
            Float* tau_in, Float* ssa_in, Float* p_in)
    {
        throw std::runtime_error("increment_2stream_by_nstream is not implemented in CUDA");
    }


    void rte_increment_nstream_by_1scalar(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout,
            Float* tau_in)
    {
        throw std::runtime_error("increment_nstream_by_1scalar is not implemented in CUDA");
    }


    void rte_increment_nstream_by_2stream(
            int* ncol, int* nlay, int* ngpt, int* nmom1,
            Float* tau_inout, Float* ssa_inout, Float* p_inout,
            Float* tau_in, Float* ssa_in, Float* g_in)
    {
        throw std::runtime_error("increment_nstream_by_2stream is not implemented in CUDA");
    }


    void rte_increment_nstream_by_nstream(
            int* ncol, int* nlay, int* ngpt, int* nmom1, int* nmom2,
            Float* tau_inout, Float* ssa_inout, Float* p_inout,
            Float* tau_in, Float* ssa_in, Float* p_in)
    {
        throw std::runtime_error("increment_nstream_by_nstream is not implemented in CUDA");
    }


    // OPTICAL PROPS - INCREMENT BYBND
    void rte_inc_1scalar_by_1scalar_bybnd(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, const Float* tau_in,
            int* nbnd, int* band_lims_gpoint)
    {
        printf("CvH: rte_inc_1scalar_by_1scalar_bybnd CUDA\n");
        optical_props_kernel_launcher_cuda::inc_1scalar_by_1scalar_bybnd(
                *ncol, *nlay, *ngpt,
                tau_inout, tau_in,
                *nbnd, band_lims_gpoint);
    }


    void rte_inc_1scalar_by_2stream_bybnd(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout,
            Float* tau_in, Float* ssa_in,
            int* nbnd, int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_1scalar_by_2stream_bybnd is not implemented in CUDA");
    }


    void rte_inc_1scalar_by_nstream_bybnd(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout,
            int* nbnd, int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_1scalar_by_nstream_bybnd is not implemented in CUDA");
    }


    void rte_inc_2stream_by_1scalar_bybnd(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout,
            Float* tau_in,
            int* nbnd, int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_2stream_by_1scalar_bybnd is not implemented in CUDA");
    }


    void rte_inc_2stream_by_2stream_bybnd(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout, Float* g_inout,
            const Float* tau_in, const Float* ssa_in, const Float* g_in,
            int* nbnd, const int* band_lims_gpoint)
    {
        printf("CvH: rte_inc_2stream_by_2stream_bybnd CUDA\n");
        optical_props_kernel_launcher_cuda::inc_2stream_by_2stream_bybnd(
                *ncol, *nlay, *ngpt,
                tau_inout, ssa_inout, g_inout,
                tau_in, ssa_in, g_in,
                *nbnd, band_lims_gpoint);
    }


    void rte_inc_2stream_by_nstream_bybnd(
            int* ncol, int* nlay, int* ngpt, int* nmom,
            Float* tau_inout, Float* ssa_inout, Float* g_inout,
            Float* tau_in, Float* ssa_in, Float* p_in,
            int* nbnd, const int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_2stream_by_nstream_bynd is not implemented in CUDA");
    }


    void rte_inc_nstream_by_1scalar_bybnd(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout,
            Float* tau_in,
            int* nbnd, const int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_nstream_by_1scalar_bybnd is not implemented in CUDA");
    }


    void rte_inc_nstream_by_2stream_bybnd(
            int* ncol, int* nlay, int* ngpt, int* nmom1,
            Float* tau_inout, Float* ssa_inout, Float* p_inout,
            Float* tau_in, Float* ssa_in, Float* g_in,
            int* nbnd, const int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_nstream_by_2stream_bybnd is not implemented in CUDA");
    }


    void rte_inc_nstream_by_nstream_bybnd(
            int* ncol, int* nlay, int* ngpt, int* nmom1, int* nmom2,
            Float* tau_inout, Float* ssa_inout, Float* p_inout,
            Float* tau_in, Float* ssa_in, Float* p_in,
            int* nbnd, const int* band_lims_gpoint)
    {
        throw std::runtime_error("inc_nstream_by_nstream_bybnd is not implemented in CUDA");
    }


    // OPTICAL PROPS - DELTA SCALING
    void rte_delta_scale_2str_k(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout, Float* g_inout)
    {
        printf("CvH: delta_scale_2str_k CUDA\n");
        optical_props_kernel_launcher_cuda::delta_scale_2str_k(
            *ncol, *nlay, *ngpt,
            tau_inout, ssa_inout, g_inout);
    }


    void rte_delta_scale_2str_f_k(
            int* ncol, int* nlay, int* ngpt,
            Float* tau_inout, Float* ssa_inout, Float* g_inout, Float* f)
    {
        throw std::runtime_error("delta_scale_2str_f_k is not implemented in CUDA");
    }

    // OPTICAL PROPS - SUBSET
    void rte_extract_subset_dim1_3d(
            int* ncol, int* nlay, int* ngpt, Float* array_in, int* ncol_start, int* ncol_end, Float* array_out)
    {
        printf("CvH: rte_extract_subset_dim1_3d CUDA\n");

        const int ncol_sub = (*ncol_end) - (*ncol_start) + 1;

        // Launch directly from the interface, as the subsetting is integrated with Array class in CUDA implementation.
        Subset_data<3> subset_data;

        subset_data.sub_strides[0] = 1;
        subset_data.strides[0] = 1;
        subset_data.starts[0] = (*ncol_start) + 1;
        subset_data.offsets[0] = 0;
        subset_data.do_spread[0] = false;

        subset_data.sub_strides[1] = ncol_sub;
        subset_data.strides[1] = (*ncol);
        subset_data.starts[1] = 1;
        subset_data.offsets[1] = 0;
        subset_data.do_spread[1] = false;

        subset_data.sub_strides[2] = ncol_sub * (*nlay);
        subset_data.strides[2] = (*ncol) * (*nlay);
        subset_data.starts[2] = 1;
        subset_data.offsets[2] = 0;
        subset_data.do_spread[2] = false;

        const int ncells = ncol_sub * (*nlay) * (*ngpt);

        constexpr int block_ncells = 64;
        const int grid_ncells = ncells/block_ncells + (ncells%block_ncells > 0);

        dim3 block_gpu(block_ncells);
        dim3 grid_gpu(grid_ncells);

        subset_kernel<<<grid_gpu, block_gpu>>>(array_out, array_in, subset_data, ncells);
    }


    void rte_extract_subset_dim2_4d(
            int* ncol, int* nlay, int* ngpt, Float* array_in, int* ncol_start, int* ncol_end, Float* array_out)
    {
        throw std::runtime_error("rte_extract_subset_dim2_4d is not implemented in CUDA");
    }


    void rte_extract_subset_absorption_tau(
            int* ncol, int* nlay, int* ngpt, Float* tau_in, Float* ssa_in, int* ncol_start, int* ncol_end, Float* tau_out)
    {
        throw std::runtime_error("rte_extract_subset_absorption_tau is not implemented in CUDA");
    }


    void rte_sum_broadband(
            int* ncol, int* nlev, int* ngpt,
            Float* gpt_flux, Float* flux)
    {
        printf("CvH: rte_sum_broadband CUDA\n");
        fluxes_kernel_launcher_cuda::sum_broadband(
                *ncol, *nlev, *ngpt,
                gpt_flux, flux);
    }

    void rte_net_broadband_full(
            int* ncol, int* nlev, int* ngpt,
            Float* gpt_flux_dn, Float* gpt_flux_up,
            Float* flux_net)
    {
        throw std::runtime_error("rte_net_broadband_full is not implemented in CUDA");
    }


    void rte_net_broadband_precalc(
            int* ncol, int* nlev,
            Float* broadband_flux_dn, Float* broadband_flux_up,
            Float* broadband_flux_net)
    {
        printf("CvH: rte_net_broadband_precalc CUDA\n");
        fluxes_kernel_launcher_cuda::net_broadband_precalc(
                *ncol, *nlev,
                broadband_flux_dn, broadband_flux_up,
                broadband_flux_net);
    }


    /*
    void rte_sum_byband(
            int* ncol, int* nlev, int* ngpt, int* nbnd,
            int* band_lims,
            Float* gpt_flux,
            Float* bnd_flux)
    {
        printf("CvH: rte_sum_byband CUDA\n");
        fluxes_kernel_launcher_cuda::sum_byband(
                *ncol, *nlev, *ngpt, *nbnd,
                band_lims,
                gpt_flux,
                bnd_flux);
    }


    void rte_net_byband_full(
            int* ncol, int* nlev, int* ngpt, int* nbnd, int* band_lims,
            Float* bnd_flux_dn, Float* bnd_flux_up, Float* bnd_flux_net)
    {
        printf("CvH: rte_net_byband_full CUDA\n");
        fluxes_kernel_launcher_cuda::net_byband_full(
                *ncol, *nlev, *ngpt, *nbnd, band_lims,
                bnd_flux_dn, bnd_flux_up, bnd_flux_net);
    }
    */
}
