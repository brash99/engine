      SUBROUTINE H_DUMP_CAL(ABORT,errmsg)
*--------------------------------------------------------
*-
*-   Purpose and Methods : Analyze scintillator information for each track 
*-
*-      Required Input BANKS     HMS_CALORIMETER
*-                               GEN_DATA_STRUCTURES
*-
*-   Output: ABORT           - success or failure
*-         : err             - reason for failure, if any
*- 
* author: John Arrington
* created: 9/7/95
*
* h_dump_cal writes out the raw calorimeterinformation for the final tracks.
* This data is analyzed by independent routines to fit the gains for each
* block.
*
* $Log$
* Revision 1.1  1995/10/09 20:16:45  cdaq
* Initial revision
*
*--------------------------------------------------------
      IMPLICIT NONE
*
      character*10 here
      parameter (here= 'H_DUMP_CAL')
*
      logical ABORT
      character*(*) errmsg
*
      INCLUDE 'hms_data_structures.cmn'
      include 'hms_calorimeter.cmn'

      integer*4 blk

      save

*
*  Write out cal fitting data.
*
      write(35,'(1x,52f7.1,1x,e11.4)') 
     &      ((hcal_realadc(blk),blk=1,hmax_cal_blocks),hsp)

      RETURN
      END