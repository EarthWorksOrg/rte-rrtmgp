#include <cstdio>
#include <openacc.h>
#include "Types.h"
#include "rrtmgp_kernel_launcher_cuda.h"

template<typename T> T* acc_to_cuda(T* ptr) { return static_cast<T*>(acc_deviceptr(ptr)); }

extern "C"
{
    void interpolation_(
            int* ncol, int* nlay,
            int* ngas, int* nflav, int* neta, int* npres, int* ntemp,
            int* flavor,
            Float* press_ref_log,
            Float* temp_ref,
            Float* press_ref_log_delta,
            Float* temp_ref_min,
            Float* temp_ref_delta,
            Float* press_ref_trop_log,
            Float* vmr_ref,
            Float* play,
            Float* tlay,
            Float* col_gas,
            int* jtemp,
            Float* fmajor, Float* fminor,
            Float* col_mix,
            Bool* tropo,
            int* jeta,
            int* jpress)
    {
        printf("CvH: interpolation\n");
        rrtmgp_kernel_launcher_cuda::interpolation(
                *ncol, *nlay,
                *ngas, *nflav, *neta, *npres, *ntemp,
                acc_to_cuda(flavor),
                acc_to_cuda(press_ref_log),
                acc_to_cuda(temp_ref),
                *press_ref_log_delta,
                *temp_ref_min,
                *temp_ref_delta,
                *press_ref_trop_log,
                acc_to_cuda(vmr_ref),
                acc_to_cuda(play),
                acc_to_cuda(tlay),
                acc_to_cuda(col_gas),
                acc_to_cuda(jtemp),
                acc_to_cuda(fmajor), acc_to_cuda(fminor),
                acc_to_cuda(col_mix),
                acc_to_cuda(tropo),
                acc_to_cuda(jeta),
                acc_to_cuda(jpress));
    }


    void compute_tau_absorption_(
            int* ncol, int* nlay, int* nband, int* ngpt,
            int* ngas, int* nflav, int* neta, int* npres, int* ntemp,
            int* nminorlower, int* nminorklower,
            int* nminorupper, int* nminorkupper,
            int* idx_h2o,
            int* gpoint_flavor,
            int* band_lims_gpt,
            Float* kmajor,
            Float* kminor_lower,
            Float* kminor_upper,
            int* minor_limits_gpt_lower,
            int* minor_limits_gpt_upper,
            Bool* minor_scales_with_density_lower,
            Bool* minor_scales_with_density_upper,
            Bool* scale_by_complement_lower,
            Bool* scale_by_complement_upper,
            int* idx_minor_lower,
            int* idx_minor_upper,
            int* idx_minor_scaling_lower,
            int* idx_minor_scaling_upper,
            int* kminor_start_lower,
            int* kminor_start_upper,
            Bool* tropo,
            Float* col_mix, Float* fmajor,
            Float* fminor, Float* play,
            Float* tlay, Float* col_gas,
            int* jeta, int* jtemp,
            int* jpress, Float* tau)
    {
        printf("CvH: compute_tau_absorption\n");
        rrtmgp_kernel_launcher_cuda::compute_tau_absorption(
                *ncol, *nlay, *nband, *ngpt,
                *ngas, *nflav, *neta, *npres, *ntemp,
                *nminorlower, *nminorklower,
                *nminorupper, *nminorkupper,
                *idx_h2o,
                acc_to_cuda(gpoint_flavor),
                acc_to_cuda(band_lims_gpt),
                acc_to_cuda(kmajor),
                acc_to_cuda(kminor_lower),
                acc_to_cuda(kminor_upper),
                acc_to_cuda(minor_limits_gpt_lower),
                acc_to_cuda(minor_limits_gpt_upper),
                acc_to_cuda(minor_scales_with_density_lower),
                acc_to_cuda(minor_scales_with_density_upper),
                acc_to_cuda(scale_by_complement_lower),
                acc_to_cuda(scale_by_complement_upper),
                acc_to_cuda(idx_minor_lower),
                acc_to_cuda(idx_minor_upper),
                acc_to_cuda(idx_minor_scaling_lower),
                acc_to_cuda(idx_minor_scaling_upper),
                acc_to_cuda(kminor_start_lower),
                acc_to_cuda(kminor_start_upper),
                acc_to_cuda(tropo),
                acc_to_cuda(col_mix), acc_to_cuda(fmajor),
                acc_to_cuda(fminor), acc_to_cuda(play),
                acc_to_cuda(tlay), acc_to_cuda(col_gas),
                acc_to_cuda(jeta), acc_to_cuda(jtemp),
                acc_to_cuda(jpress), acc_to_cuda(tau));
    }


    void compute_tau_rayleigh_(
            int* ncol, int* nlay, int* nband, int* ngpt,
            int* ngas, int* nflav, int* neta, int* npres, int* ntemp,
            int* gpoint_flavor,
            int* band_lims_gpt,
            Float* krayl,
            int* idx_h2o, Float* col_dry, Float* col_gas,
            Float* fminor, int* jeta,
            Bool* tropo, int* jtemp,
            Float* tau_rayleigh)
    {
        printf("CvH: compute_tau_rayleigh\n");
        rrtmgp_kernel_launcher_cuda::compute_tau_rayleigh(
                *ncol, *nlay, *nband, *ngpt,
                *ngas, *nflav, *neta, *npres, *ntemp,
                acc_to_cuda(gpoint_flavor),
                acc_to_cuda(band_lims_gpt),
                acc_to_cuda(krayl),
                *idx_h2o, acc_to_cuda(col_dry), acc_to_cuda(col_gas),
                acc_to_cuda(fminor), acc_to_cuda(jeta),
                acc_to_cuda(tropo), acc_to_cuda(jtemp),
                acc_to_cuda(tau_rayleigh));
    }


    void compute_planck_source_(
            int* ncol, int* nlay, int* nbnd, int* ngpt,
            int* nflav, int* neta, int* npres, int* ntemp,
            int* nPlanckTemp,
            Float* tlay,
            Float* tlev,
            Float* tsfc,
            int* sfc_lay,
            Float* fmajor,
            int* jeta,
            Bool* tropo,
            int* jtemp,
            int* jpress,
            int* gpoint_bands,
            int* band_lims_gpt,
            Float* pfracin,
            Float* temp_ref_min, Float* totplnk_delta,
            Float* totplnk,
            int* gpoint_flavor,
            Float* sfc_src,
            Float* lay_src,
            Float* lev_src_inc,
            Float* lev_src_dec,
            Float* sfc_src_jac)
    {
        int* gpoint_bands_gpu = (int*) acc_malloc((*ngpt) * sizeof(int));
        acc_memcpy_to_device(gpoint_bands_gpu, gpoint_bands, (*ngpt) * sizeof(int));
        printf("CvH: compute_planck_source %p\n", acc_to_cuda(gpoint_bands_gpu));
        
        rrtmgp_kernel_launcher_cuda::Planck_source(
                *ncol, *nlay, *nbnd, *ngpt,
                *nflav, *neta, *npres, *ntemp,
                *nPlanckTemp,
                acc_to_cuda(tlay),
                acc_to_cuda(tlev),
                acc_to_cuda(tsfc),
                *sfc_lay,
                acc_to_cuda(fmajor),
                acc_to_cuda(jeta),
                acc_to_cuda(tropo),
                acc_to_cuda(jtemp),
                acc_to_cuda(jpress),
                // acc_to_cuda(gpoint_bands),
                acc_to_cuda(gpoint_bands_gpu),
                acc_to_cuda(band_lims_gpt),
                acc_to_cuda(pfracin),
                *temp_ref_min, *totplnk_delta,
                acc_to_cuda(totplnk),
                acc_to_cuda(gpoint_flavor),
                acc_to_cuda(sfc_src),
                acc_to_cuda(lay_src),
                acc_to_cuda(lev_src_inc),
                acc_to_cuda(lev_src_dec),
                acc_to_cuda(sfc_src_jac));

        acc_free(gpoint_bands_gpu);
    }
}