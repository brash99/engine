
      subroutine s_fill_dc_fp_hist(Abort,err)
*
*     routine to fill histograms with sos_focal_plane varibles
*
*     Author:	D. F. Geesaman
*     Date:     30 March 1994
*     Modified: 9 April 1994        DFG
*                                   Transfer ID in common block
*                                   Implement flag to turn block on
* $Log$
* Revision 1.1  1994/04/13 18:10:39  cdaq
* Initial revision
*
*--------------------------------------------------------
       IMPLICIT NONE
*
       character*50 here
       parameter (here= 's_fill_dc_fp_hist')
*
       logical ABORT
       character*(*) err
       real*4  histval
       integer*4 itrk

*
       include 'gen_data_structures.cmn'
       include 'sos_tracking_histid.cmn'
*
       SAVE
*--------------------------------------------------------
*
       ABORT= .FALSE.
       err= ' '
*
* Is this histogram flag turned on
       if(sturnon_focal_plane_hist .ne. 0 ) then
* Make sure there is at least 1 track
        if(SNTRACKS_FP .gt. 0 ) then
* Loop over all hits
           do itrk=1,SNTRACKS_FP
             call hf1(sidsx_fp,SX_FP(itrk),1.)
             call hf1(sidsy_fp,SY_FP(itrk),1.)
             call hf1(sidsxp_fp,SXP_FP(itrk),1.)
             call hf1(sidsyp_fp,SYP_FP(itrk),1.)
             if(SCHI2_FP(itrk) .gt. 0 ) then
               histval=log10(SCHI2_FP(itrk))            
             else 
               histval = 10.
             endif
             call hf1(sidslogchi2_fp,histval,1.)
             histval= SNFREE_FP(itrk)
             call hf1(sidsnfree_fp,histval,1.)
             if( SNFREE_FP(itrk) .ne.0) then
               histval= SCHI2_FP(itrk) /  SNFREE_FP(itrk)
             else
               histval = -1.
            endif
            call hf1(sidschi2perdeg_fp,histval,1.)
*
* 
         enddo   ! end loop over hits
       endif     ! end test on zero hits       
      endif      ! end test on histogramming flag
      RETURN
      END
