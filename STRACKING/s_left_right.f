      subroutine S_LEFT_RIGHT(ABORT,err)
* Warning: This routine contains lots of gobbledeguk that won't work if the
*     number of chambers is changed to 3.
*
*
*     This routine fits stubs to all possible left-right combinations of
*     drift distances and chooses the set with the minimum chi**2
*     It then fills the SDC_WIRE_COORD variable for each hit in a good
*     space point.
*     d. f. geesaman           31 August 1993
* $Log$
* Revision 1.2  1994/11/22 21:14:25  cdaq
* (SPB) Recopied from hms file and modified names for SOS
* (SAW) Don't count on Mack's monster if statement working for
*       sdc_num_chambers > 2
*
* Revision 1.1  1994/02/21  16:14:42  cdaq
* Initial revision
*
*
      implicit none
      save
      include 'gen_data_structures.cmn'
      include 'sos_tracking.cmn'
      include 'sos_geometry.cmn'
*
      externaljbit                            ! cernlib bit routine
      integer*4 jbit
*
*     local variables
*
      character*50 here
      parameter (here= 'S_LEFT_RIGHT')
*
      logical ABORT
      character*(*) err
      integer*4 isp, ihit,iswhit, idummy, pmloop
      integer*4 nplusminus
      integer*4 numhits
      integer*4 hits(smax_hits_per_point), pl(smax_hits_per_point)
      integer*4 pindex
      real*4 wc(smax_hits_per_point)
      integer*4 plane, isa_y1, isa_y2
      integer*4 plusminusknown(smax_hits_per_point)
      real*4 plusminus(smax_hits_per_point)
      real*4 plusminusbest(smax_hits_per_point)
      real*4 chi2
      real*4 minchi2
      real*4 stub(4)
      logical smallAngOk
*
      ABORT= .FALSE.
      err=':'

* initialize sdc_sing_wcoord (or else!)
      do plane=1,SMAX_NUM_DC_PLANES
        sdc_sing_wcoord(plane) = -100.
      enddo

*d    jm 10/2/94 added initialization/setting of gplanehdc1(isp)/2 pattern
*     units. Presently we are accepting 5/6 or 6/6 planes per chamber. 

      do isp=1,snspace_points_tot       ! loop over all space points
        gplanesdc1(isp) = 0
        gplanesdc2(isp) = 0
        minchi2=1e10
        smallAngOK = .FALSE.
        isa_y1 = 0
        isa_y2 = 0
        numhits=sspace_point_hits(isp,1)
        nplusminus=2**numhits
        do ihit=1,numhits
          hits(ihit)=sspace_point_hits(isp,2+ihit)
          pl(ihit)=SDC_PLANE_NUM(hits(ihit))
          
          if(pl(ihit).ge.1 .and. pl(ihit).le.6)then
            gplanesdc1(isp)=jibset(gplanesdc1(isp),pl(ihit)-1)
          else
            gplanesdc2(isp)=jibset(gplanesdc2(isp),pl(ihit)-7)
          endif

          wc(ihit)=SDC_WIRE_CENTER(hits(ihit))
          plusminusknown(ihit) = 0
          if(pl(ihit).eq.2 .OR. pl(ihit).eq.8)  isa_y1 = ihit
          if(pl(ihit).eq.5 .OR. pl(ihit).eq.11) isa_y2 = ihit
        enddo
          

* djm 10/2/94 check bad sdc pattern units to set the index for the inverse
* matrix SAAINV(i,j,pindex).
*
        if(pl(1).ge.1 .and. pl(1).le.6)then !use first hit to test if sdc1
         
          if(gplanesdc1(isp).eq.63)then
            pindex=13                   !first 6 bits set, so 6 planes hit
          else
            if(gplanesdc1(isp).eq.62)then
              pindex=1                  !missing lowest order bit, missing x1
            else
              if(gplanesdc1(isp).eq.61)then
                pindex=2
              else
                if(gplanesdc1(isp).eq.59)then
                  pindex=3
                else
                  if(gplanesdc1(isp).eq.55)then
                    pindex=4
                  else
                    if(gplanesdc1(isp).eq.47)then
                      pindex=5
                    else
                      if(gplanesdc1(isp).eq.31)then
                        pindex=6
                      else
                        pindex=-1       !multiple missing planes or other problem
                      end if
                    end if
                  end if
                end if
              end if
            end if
          end if

        else                            !must be sdc2

          if(gplanesdc2(isp).eq.63)then
            pindex=14                   !first 6 bits set, so 6 planes hit
          else
            if(gplanesdc2(isp).eq.62)then
              pindex=7                  !missing lowest order bit, missing x1
            else
              if(gplanesdc2(isp).eq.61)then
                pindex=8
              else
                if(gplanesdc2(isp).eq.59)then
                  pindex=9
                else
                  if(gplanesdc2(isp).eq.55)then
                    pindex=10
                  else
                    if(gplanesdc2(isp).eq.47)then
                      pindex=11
                    else
                      if(gplanesdc2(isp).eq.31)then
                        pindex=12
                      else
                        pindex=-2       !multiple missing planes or other problem
                      end if
                    end if
                  end if
                end if
              end if
            end if
          end if
          
        endif                           !end test whether sdc1 or sdc2


*     check if small angle L/R determination of Y and Y' planes is possible
        if(isa_y1.gt.0 .AND. isa_y2.gt.0) smallAngOK = .TRUE.
        if((sSmallAngleApprox.ne.0) .AND. (smallAngOK)) then
          if(wc(isa_y2).le.wc(isa_y1)) then
            plusminusknown(isa_y1) = -1
            plusminusknown(isa_y2) = 1
          else
            plusminusknown(isa_y1) = 1
            plusminusknown(isa_y2) = -1
          endif
          nplusminus = 2**(numhits-2)
        endif

*     use bit value of integer word to set + or -
        do pmloop=0,nplusminus-1
          iswhit = 1
          do ihit=1,numhits
            if(plusminusknown(ihit).ne.0) then
              plusminus(ihit) = float(plusminusknown(ihit))
            else
              if(jbit(pmloop,ihit).eq.1) then
                plusminus(ihit)=1.0
              else
                plusminus(ihit)=-1.0
              endif
              iswhit = iswhit + 1
            endif
          enddo
*     now passign pl(ihit) so it doesn't have to be recalculated every iteration

          call s_find_best_stub(numhits,hits,pl,pindex,plusminus,stub,chi2)
          if(sdebugstubchisq.ne.0) then
            write(sluno,'('' sos pmloop='',i4,''   chi2='',e14.6)')
     &           pmloop,chi2
          endif
          if (chi2.lt.minchi2)  then
            minchi2=chi2
            do idummy=1,numhits
              plusminusbest(idummy)=plusminus(idummy)
            enddo
            do idummy=1,4
              sbeststub(isp,idummy)=stub(idummy)
            enddo
          endif                         ! end if on lower chi2
        enddo                           ! end loop on possible left-right
*
*     calculate final coordinate based on plusminusbest
*           
        do ihit=1,numhits
          SDC_WIRE_COORD(sspace_point_hits(isp,ihit+2))=
     &         SDC_WIRE_CENTER(sspace_point_hits(isp,ihit+2)) +
     &         plusminusbest(ihit)*SDC_DRIFT_DIS(sspace_point_hits(isp,ihit
     $         +2))
        enddo
*
*     stubs are calculated in rotated coordinate system
*     use first hit to determine chamber
        plane=SDC_PLANE_NUM(hits(1))
        stub(3)=(sbeststub(isp,3) - stanbeta(plane))
     &       /(1.0 + sbeststub(isp,3)*stanbeta(plane))
        stub(4)=sbeststub(isp,4)
     &       /(sbeststub(isp,3)*ssinbeta(plane)+scosbeta(plane))

        stub(1)=sbeststub(isp,1)*scosbeta(plane) 
     &       - sbeststub(isp,1)*stub(3)*ssinbeta(plane)
        stub(2)=sbeststub(isp,2) 
     &       - sbeststub(isp,1)*stub(4)*ssinbeta(plane)
        sbeststub(isp,1)=stub(1)
        sbeststub(isp,2)=stub(2)
        sbeststub(isp,3)=stub(3)
        sbeststub(isp,4)=stub(4)

*
      enddo                             ! end loop over space points
*
*     write out results if sdebugflagstubs is set
      if(sdebugflagstubs.ne.0) then
        call s_print_stubs
      endif
      return
      end
        
