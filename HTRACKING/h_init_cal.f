*=======================================================================
      subroutine h_init_cal(abort,errmsg)
*=======================================================================
*-
*-      Purpose: HMS Calorimeter Initialization
*-
*-      Created: 20 Mar 1994      Tsolak A. Amatuni
* $Log$
* Revision 1.3  1995/05/22 19:39:13  cdaq
* (SAW) Split gen_data_data_structures into gen, hms, sos, and coin parts"
*
* Revision 1.2  1994/06/14  03:12:22  cdaq
* (DFG) make all parameters CTP, not hard wired
*
* Revision 1.1  1994/04/13  15:39:11  cdaq
* Initial revision
*
*-----------------------------------------------------------------------
*
*
      implicit none
      save
*
      logical abort
      character*(*) errmsg
      character*10 here
      parameter (here='H_INIT_CAL')
*
      integer*4 block      !Block number
      integer*4 row        !Row number
      integer*4 column     !Column number
      real*4 xi   !Temporary
      real*4 zi   !Temporary
*
      include 'hms_data_structures.cmn'
      include 'hms_calorimeter.cmn'
*
*-----Initialize the positions
      do column=1,hmax_cal_columns
         do row=1,hmax_cal_rows
            block=row+hmax_cal_rows*(column-1)
*
            if(column.eq.1) then
               hcal_block_xc(block)=hcal_1pr_top(row)+0.5*hcal_1pr_thick
               hcal_block_yc(block)=0.5*(hcal_1pr_left+hcal_1pr_right)
               hcal_block_zc(block)=hcal_1pr_zpos+0.5*hcal_1pr_thick
            else if(column.eq.2) then
               hcal_block_xc(block)=hcal_2ta_top(row)+0.5*hcal_2ta_thick
               hcal_block_yc(block)=0.5*(hcal_2ta_left+hcal_2ta_right)
               hcal_block_zc(block)=hcal_2ta_zpos+0.5*hcal_2ta_thick
            else if(column.eq.3) then
               hcal_block_xc(block)=hcal_3ta_top(row)+0.5*hcal_3ta_thick
               hcal_block_yc(block)=0.5*(hcal_3ta_left+hcal_3ta_right)
               hcal_block_zc(block)=hcal_3ta_zpos+0.5*hcal_3ta_thick
            else
               hcal_block_xc(block)=hcal_4ta_top(row)+0.5*hcal_4ta_thick
               hcal_block_yc(block)=0.5*(hcal_4ta_left+hcal_4ta_right)
               hcal_block_zc(block)=hcal_4ta_zpos+0.5*hcal_4ta_thick
            endif
         enddo   !End loop over rows
      enddo   !End loop over columns
*
      hcal_block_xsize= hcal_4ta_top(2) - hcal_4ta_top(1)
      hcal_block_ysize= hcal_4ta_left - hcal_4ta_right
      hcal_block_zsize= hcal_4ta_thick
      hcal_xmax= hcal_4ta_top(hcal_4ta_nr) + hcal_block_xsize
      hcal_xmin= hcal_4ta_top(1)
      hcal_ymax= hcal_4ta_left
      hcal_ymin= hcal_4ta_right
      hcal_zmin= hcal_1pr_zpos
      hcal_zmax= hcal_4ta_zpos
      hcal_fv_xmin=hcal_xmin+5.
      hcal_fv_xmax=hcal_xmax-5.
      hcal_fv_ymin=hcal_ymin+5.
      hcal_fv_ymax=hcal_ymax-5.
      hcal_fv_zmin=hcal_zmin
      hcal_fv_zmax=hcal_zmax
*
      return
      end
