      SUBROUTINE G_reconstruction(ABORT,err)
*----------------------------------------------------------------------
*-       Prototype hall C reconstruction routine
*- 
*-   Purpose and Methods : Given previously filled data structures,
*-                         reconstruction is performed and status returned
*- 
*-   Output: ABORT	- success or failure
*-         : err	- reason for failure, if any
*- 
*-   Created  20-Oct-1993   Kevin B. Beard
*-   Modified 20-Nov-1993   KBB for new error routines
*-    $Log$
*-    Revision 1.2  1994/02/01 21:28:48  cdaq
*-    Add call to G_decode_event_by_banks
*-
*-
*- All standards are from "Proposal for Hall C Analysis Software
*- Vade Mecum, Draft 1.0" by D.F.Geesamn and S.Wood, 7 May 1993
*-
*--------------------------------------------------------
      IMPLICIT NONE
      SAVE
*
      character*16 here
      parameter (here= 'G_reconstruction')
*     
      logical ABORT
      character*(*) err
*     
      INCLUDE 'gen_data_structures.cmn'
*
      logical HMS_ABORT,SOS_ABORT
      character*1024 HMS_err,SOS_err
*--------------------------------------------------------
*
      err= ' '                                  !erase any old errors
*
*-HMS reconstruction
      call H_reconstruction(HMS_ABORT,HMS_err)
*
*-SOS reconstruction
      call S_reconstruction(SOS_ABORT,SOS_err)
*
      IF(.NOT.HMS_ABORT .and. .NOT.SOS_ABORT) THEN
*
*-COIN reconstruction
*
         call C_reconstruction(ABORT,err)
*
      ELSEIF(HMS_ABORT) THEN
*     
*-HMS only
*
         ABORT= SOS_ABORT                       !nonfatal error?
         err= SOS_err                           !warning about SOS
         call G_log_message('WARNING: '//err)
*
      ELSEIF(SOS_ABORT) THEN
*
*-SOS only
*
         ABORT= HMS_ABORT                       !nonfatal error?
         err= HMS_err                           !warning about HMS
         call G_log_message('WARNING: '//err)
*
      ELSE
*     error from both HMS and SOS
         ABORT= .TRUE.
         call G_prepend(HMS_err//' & '//SOS_err,err)
*
      ENDIF
*
      IF(ABORT) call G_add_path(here,err)
*
      RETURN
      END
                                                                                                                                                                                                                          