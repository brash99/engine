      subroutine s_trans_cal(abort,errmsg)
*=======================================================================
*-
*-      Purpose: Computes the energy deposited in each of the hit
*-               counters, the energy deposition in calorimeter
*-               columns and the total energy deposition, using only
*-               the calorimeter information.
*-               The energy depositions are not corrected yet for
*-               impact point coordinate dependence.
*-               The subroutine also returns the X and Z coordinates
*-               of the hit block centers.
*-
*-      Input Banks: SOS_SPARSIFIED_CAL, SOS_CAL_CONST,SOS_CAL_MONITOR
*-
*-      Output Bank: SOS_DECODED_CAL
*-
*-      Created: 15 Mar 1994      Tsolak A. Amatuni
* $Log$
* Revision 1.2  1994/11/23 14:45:40  cdaq
* * (SPB) Recopied from hms file and modified names for SOS
*
* Revision 1.1  1994/02/21  16:42:44  cdaq
* Initial revision
*
*--------------------------------------------------------
      implicit none
      save
*
      logical abort
      character*(*) errmsg
      character*11 here
      parameter (here='S_TRANS_CAL')
*
      integer*4 nb      !Block number
      integer*4 nh      !Hit number
      integer*4 row     !Row number
      integer*4 col     !Column number
      real*4 adc        !ADC-PED value
*
      include 'gen_data_structures.cmn'
      include 'sos_calorimeter.cmn'
*
*      Sparsify the raw data
*
      call s_sparsify_cal(abort,errmsg)
      if(abort) then
        call g_add_path(here,errmsg)
        return
      endif
*
      snhits_cal =0
      scal_e1    =0.
      scal_e2    =0.
      scal_e3    =0.
      scal_e4    =0.
      scal_et    =0.
      if(scal_num_hits.le.0) go to 100   !Return
*
*      Loop over hits
*
      do nh=1,scal_num_hits
        row=scal_rows(nh)
        col=scal_cols(nh)
        adc=scal_adcs(nh)
        nb =row+smax_cal_rows*(col-1)
*
*------Determine position and energy deposition for each block
        sblock_xc(nh)=scal_block_xc(nb)
        sblock_zc(nh)=scal_block_zc(nb)
        sblock_de(nh)=adc*scal_cal_const(nb)*scal_gain_cor(nb)
*
*------Accumulate the integral energy depositions
        if(col.eq.1) scal_e1=scal_e1+sblock_de(nh)
        if(col.eq.2) scal_e2=scal_e2+sblock_de(nh)
        if(col.eq.3) scal_e3=scal_e3+sblock_de(nh)
        if(col.eq.4) scal_e4=scal_e4+sblock_de(nh)
        scal_et=scal_et+sblock_de(nh)
      enddo                             !End loop over hits
      snhits_cal=scal_num_hits
*
  100 continue
      if(sdbg_decoded_cal.gt.0) call s_prt_cal_decoded
*
      return
      end
