       subroutine total_eloss(arm,prt,z,a,tgthick,dens,angle,tgangle,
     &                          beta,e_loss)

*------------------------------------------------------------------------------
*-         Prototype C routine
*- 
*-
*-    Purpose and Method :  In separate calls, calculate the energy loss for 
*-                          the incident electron in the target OR the energy  
*-                          loss for exiting particles in the target and 
*-                          other materials like windows. Cryogenic targets
*-                          must be beer-can cells. Solid targets are okay too.
*-                          Ytarget information is NOT used; all calculations
*-                          assume the reaction vertex is at the target center.
*-
*-    Output: loss            -   energy loss for the arm requested
*-    Created   1-Dec-1995  Rolf Ent
*
* $Log$
* Revision 1.4  1999/02/10 17:34:41  csa
* Numerous corrections and improvements (D. Mack, K. Vansyoc, J. Volmer)
*
* Revision 1.2  1996/01/24 16:31:35  saw
* (JRA) Cleanup
*
* Revision 1.1  1996/01/17 19:12:32  cdaq
* Initial revision
*
*------------------------------------------------------------------------------
**********************
* LH2 and LD2 targets
**********************
*
* Incoming beam sees the following materials to target center:
*    1.  a 3.0 mil Al-foil (upstream endcap of target) J. Dunne Dec 96
*    2.  half the target thickness
*
* Any particle exiting target center sees the following materials:  
*    3. Particle leaves thru side-walls:1.325 inch of target material corrected
* for the spectrometer angle, OR    
*       Particle leaves thru downstream window: half the target length, correc-
* ted for the spectrometer angle.
*
*    4.  A 5.0 mil Al-foil target wall thickness (J. Dunne Dec 96), corrected 
* for spectrometer angle.
*
****************** 
* Solid targets:
****************** 
*
* Incoming beam sees the following materials to target center:
*     1.  half the target thickness, corrected for the spectrometer angle.
* 
* Any particle exiting target center sees the following materials:
*     2.  half the target thickness, corrected for the spectrometer angle
*
***************************************************
*     Additional materials (irregardless of target):
***************************************************
*     * effective density for kevlar is 0.74 
*     * effective z for CH2 is 2.67, effective a is 4.67
*                                (values confirmed by T. Keppel Mar. 98)
*
*	HMS particles only: 
*	1. 16 mil Aluminum scattering chamber window (J. Mitchell Feb. 98)
*	2. 15 cm of air between chamber window and HMS entrance window.
*          *effective a for air is 14.68, effective z is 7.32, dens is .00121
*     	3. HMS entrance window, 17 mil kevlar and 5 mil mylar. 
*                                 (values confirmed by T. Keppel Mar. 98)
*
*	SOS particles only: 
*	1. 8.0 mil Al-foil scattering chamber window (J.Mitchell Feb 98)
*	2. 15 cm of air between chamber window and HMS entrance window.
*          *effective a for air is 14.68, effective z is 7.32, dens is .00121
*  	2.  SOS entrance window, 6 mil kevlar and 1.5 mil mylar.
*                                  (values confirmed by T. Keppel Mar. 98)
     
      IMPLICIT NONE
      SAVE
*
      include 'gen_data_structures.cmn'
      include 'hms_data_structures.cmn'
      include 'sos_data_structures.cmn'
      include 'gen_constants.par'
*

*
      INTEGER arm                       ! 0 : incident beam
                                        ! 1 : HMS
                                        ! 2 : SOS
      LOGICAL prt                       ! .true. : electron
                                        ! .false. : non-electron (beta .lt. 1)
      LOGICAL liquid

      REAL*4 crit_angle,tg_spect_angle
      REAL*4 z,a,tgthick,dens,angle,tgangle,beta
      REAL*4 thick,thick_side,thick_front,e_loss,total_loss
      REAL*4 targ_win_loss,front_loss,back_loss,cell_wall_loss
      REAL*4 scat_win_loss,air_loss,h_win_loss,s_win_loss
      REAL*4 electron
      REAL*8 beta_temp,gamma_temp,X_temp,frac_temp,p_temp
      REAL*4 velocity

********************INITIALIZE ENERGY LOSS VARIABLES*****************
      e_loss         = 0.0
      total_loss     = 0.0
      targ_win_loss  = 0.0
      front_loss     = 0.0
      back_loss      = 0.0
      cell_wall_loss = 0.0
      scat_win_loss  = 0.0
      air_loss       = 0.0
      h_win_loss     = 0.0
      s_win_loss     = 0.0
      liquid =.FALSE.
*********************ENABLE SWITCH***********************************
      if(gen_eloss_enable.eq.0.) goto 100  !if 0 don't do eloss correction.
***********************SETUP OF PARAMETERS****************************

*******DEFAULT SETTINGS********************************** 
*
*     These default settings are the original values from the first
*     total_eloss.f program.
*********************************************************    
*target cell****************
      if(gcell_radius.eq.0.0) gcell_radius = 1.325*2.54
      if(gz_cell.eq.0.0) gz_cell = 13.0
      if(ga_cell.eq.0.0) ga_cell = 27.0
      if(gcell_den.eq.0.0) gcell_den = 2.70
      if(gwall_thk.eq.0.0) gwall_thk = 0.005*2.54*gcell_den
      if(gend_thk.eq.0.0) gend_thk = 0.005*2.54*gcell_den
      if(gfront_thk.eq.0.0) gfront_thk = 0.003*2.54*gcell_den ! aluminum front window

*HMS********
*    HMS scattering chamber window specs.********** 
      if(hscat_win_den.eq.0.0) hscat_win_den = 2.70
      if(hscat_win_thk.eq.0.0) hscat_win_thk = 0.016*2.54*hscat_win_den
      if(hscat_win_z.eq.0.0) hscat_win_z = 13.0
      if(hscat_win_a.eq.0.0) hscat_win_a = 27.0
*    HMS entrance window specs.********************
      if(hdet_ent_thk.eq.0.0) hdet_ent_thk = 0.005*2.54*1.35
     &      + 0.017*2.54*0.74
      if(hdet_ent_den.eq.0.0) hdet_ent_den = (5.0*1.35
     &      + 17.0*0.74)/22.
*    HMS scattering chamber window specs.********** 
      if(hdet_ent_z.eq.0.0) hdet_ent_z = 2.67
      if(hdet_ent_a.eq.0.0) hdet_ent_a = 4.67
*SOS********
*    SOS scattering chamber window specs.**********
      if(sscat_win_den.eq.0.0) sscat_win_den = 2.70
      if(sscat_win_thk.eq.0.0) sscat_win_thk = 0.008*2.54*sscat_win_den
      if(sscat_win_z.eq.0.0) sscat_win_z = 13.0
      if(sscat_win_a.eq.0.0) sscat_win_a = 27.0
*    SOS entrance window specs.********************
      if(sdet_ent_thk.eq.0.0) sdet_ent_thk = 0.0015*2.54*1.35
     &      + 0.006*2.54*0.74
      if(sdet_ent_den.eq.0.0) sdet_ent_den = (1.5*1.35
     &      + 6.0*0.74)/7.5
      if(sdet_ent_z.eq.0.0) sdet_ent_z = 2.67
      if(sdet_ent_a.eq.0.0) sdet_ent_a = 4.67
***********END OF DEFAULT SETTINGS***********************


*******DIVIDE BY ZERO CHECK**************************************
      if (z.eq.0.0) then
         write(6,*) 'total_eloss: gtarg_z = 0.0, return immediately'
         goto 100
      endif
      if (a.eq.0.0) then
         write(6,*) 'total_eloss: gtarg_a = 0.0, return immediately'
         goto 100
      endif
      if(tgthick.eq.0.0) then
         write(6,*)'total_eloss: gtarg_thick = 0.0, return immediately'
         goto 100
      endif
      if(dens.eq.0.0) then
         write(6,*)'total_eloss: gtarg_dens = 0.0, return immediately'
         goto 100
      endif
      if((angle.eq.0.0).and.(arm.ne.0)) then 
         write(6,*)'total_eloss: angle = 0.0, using centr spectr angle'
         if (arm.eq.1) angle=htheta_lab*3.14159/180.
         if (arm.eq.2) angle=stheta_lab*3.14159/180.
      endif
      if((arm.ne.0).and.(abs(angle-3.14159/2.).lt.0.0001)) then
         write(6,*) 'total_eloss: angle = 90 degrees, using centr spectr angle'
         if (arm.eq.1) angle=htheta_lab*3.14159/180.
         if (arm.eq.2) angle=stheta_lab*3.14159/180.
      endif
      if((z.eq.0.0).or.(a.eq.0.0).or.(tgthick.eq.0.0).or.(dens.eq.0.0)
     &     .or.((arm.ne.0).and.((angle.eq.0).or.(angle.eq.3.14159/2.)))) THEN
          write(6,*)'total_eloss: divide by zero error' 
          GOTO 100
      ENDIF  

 10            format(7(2x,A10))
 20            format(12x,6(2x,f10.9))
 30            format(5(2x,A10))
 40            format(12x,4(2x,f10.9))
 50            format(12x,3(2x,f10.9))
 60            format(4(A12))
 70            format(10(A11))
 80            format(2x,I9,9(2x,f9.6))
***********************END SETUP******************************

*******************************************************************************
* With the adaptation of a new, beta-dependent energy loss correction formula
* for electrons, it became necessary to give the velocity of electrons in terms
* of log_10(beta*gamma), since REAL*4 was not good enough to distinguish the
* beta of electrons from 1. For hadrons, nothing will change.
*******************************************************************************

      velocity=0.
      if(gelossdebug.ne.0) then
         write(6,'(3A10)') 'gpbeam','hsp','ssp'
         write(6,'(3(2x,f8.5))') gpbeam,hsp,ssp
      endif

      if (prt) then
         if (arm.eq.0) then
            p_temp=gpbeam
         elseif (arm.eq.1) then
            p_temp=hsp
         elseif (arm.eq.2) then
            p_temp=ssp
         else
            write(6,*) 'total_eloss: no arm specified for electron velocity'
         endif

         if (p_temp.lt.1.e-4) write(6,*) 'total_eloss: p_temp=0, use 0.1 GeV/c'

         p_temp=max(p_temp,.1)
         frac_temp=mass_electron/p_temp

         if(gelossdebug.ne.0) write(6,*) 'total_eloss: p_temp=',p_temp
         if(gelossdebug.ne.0) write(6,*) 'total_eloss: frac_temp=',frac_temp

         beta_temp=1./sqrt(1.+frac_temp**2)
         gamma_temp=sqrt(1.+frac_temp**2)/frac_temp
         X_temp=log(beta_temp*gamma_temp)/log(10.)
         
         velocity=X_temp
      else
         velocity=beta
      endif

**************************************************************************
* Calculate the angle at which the ejectile passes through the side of the
* target cell rather than the end.
**************************************************************************

       if ((tgthick.ne.0.).and.(dens.ne.0.)) then
          crit_angle= atan(gcell_radius/(tgthick/dens/2))
       else
          crit_angle= 0.45
       endif

**************************************************************************
* Define hydrogen, deuterium and 3,4He as liquid targets: z<=2
**************************************************************************

       if (z.le.2.4) liquid =.TRUE. 

**************************************************************************
* For debugging purposes, print out the variables that have been given
* over to the subroutine
**************************************************************************

       if (gelossdebug.ne.0) then
          electron=0.0
          if (prt) electron=1.0
          write(6,70) 'arm','electron?','ztgt','atgt','tgtdens','spec_angle'
     &              ,'tgangle','velocity','e_loss'
          write(6,80) arm,electron,z,a,dens,angle,tgangle,velocity,e_loss
          write(6,*) ' '
       endif

********************************************************************
* Calculate the electron beam energy loss before the target center. 
********************************************************************

      if(arm.eq.0) then

         if(liquid) then			! cryo target
            call loss(.true.,gz_cell,ga_cell,gfront_thk,gcell_den,velocity,
     &                 targ_win_loss)	!aluminum
            total_loss = total_loss + targ_win_loss
            thick = tgthick/2.
            call loss(.true.,z,a,thick,dens,velocity,front_loss) !liquid
            total_loss = total_loss + front_loss
         else
            if (abs(sin(angle)).ge.0.01) then
               thick = tgthick/2./abs(sin(tgangle))
            else
               thick = tgthick/2./0.01
            endif
            call loss(.true.,z,a,thick,dens,velocity,front_loss) !liquid
            total_loss = total_loss + front_loss
         endif
* debug output for electron beam loss
         if(gelossdebug.ne.0)then
            write(6,60) 'Ebeam loss:','window','front','total'
            write(6,50) targ_win_loss,front_loss,total_loss
            write(6,*) ' '
         endif
         e_loss = total_loss
         goto 100
      endif

*********************************************************************
*Calculate the energy loss of ejectile after the target center.
*********************************************************************

*Liquid target*********
         if (liquid .and. arm.ne.0) then
            thick_front = 0.0
            if (cos(angle).ge.0.01) then
               thick_front= abs(tgthick/2./cos(angle))
            else
               thick_front= abs(tgthick/2./0.01)
            endif
            if (abs(sin(angle)).ge.0.01) then
               thick_side  = abs(gcell_radius*dens/abs(sin(angle)))
            else
               thick_side  = abs(gcell_radius*dens/0.01)
            endif

*Through the end of the cell.
            if (angle.le.crit_angle)then        
               call loss(prt,z,a,thick_front,dens,velocity,back_loss)  !liquid
               total_loss = total_loss + back_loss
               if (cos(angle).ge.0.01) then
                  thick = abs(gend_thk/cos(angle))
               else
                  thick = abs(gend_thk/0.01)
               endif
               call loss(prt,gz_cell,ga_cell,thick,gcell_den,velocity,
     &                   cell_wall_loss)                          !aluminum
               total_loss = total_loss + cell_wall_loss
*Through the side of the cell. 
             else					
                call loss(prt,z,a,thick_side,dens,velocity,back_loss)  !liquid
                total_loss = total_loss + back_loss
                if (abs(sin(angle)).ge.0.01) then
                   thick = abs(gwall_thk/abs(sin(angle)))
                else
                   thick = abs(gwall_thk/0.01)
                endif
                call loss(prt,gz_cell,ga_cell,thick,gcell_den,velocity,
     &                     cell_wall_loss)                        !aluminum
                total_loss = total_loss + cell_wall_loss
             endif

*Solid target************
         else    

*     In any ordinary case, the solid target has angle of 90 degrees
*     with respect to the beam direction: tgangle=90.*degrad

*     csa 1/5/99 -- Here I define tgangle > 90 deg to mean that the
*     solid target is facing the SOS.

            if (arm.eq.1) then  ! HMS
               tg_spect_angle = angle + tgangle
            elseif (arm.eq.2) then ! SOS
               tg_spect_angle = angle - tgangle
            else
               write(6,*)' '
               write(6,*)' bad ''arm'' in total_eloss.f'
               write(6,*)' '
            endif

            if (abs(sin(tg_spect_angle)).ge.0.01) then
               thick = abs((tgthick/2.)/abs(sin(tg_spect_angle)))
            else
               thick = abs((tgthick/2.)/0.01)
            endif
            call loss(prt,z,a,thick,dens,velocity,back_loss) !generic solid target

            total_loss = total_loss + back_loss
         endif

************************************
* Now calculate the HMS energy loss.  
************************************

      if (arm.eq.1) then			! HMS

* 16 mil aluminum scattering chamber window on HMS side
         call loss(prt,hscat_win_z,hscat_win_a,hscat_win_thk,
     &               hscat_win_den,velocity,scat_win_loss) !aluminum
         total_loss = total_loss + scat_win_loss

* ENERGY LOSS IN AIR GAP BEWTEEN THE CHAMBER AND THE ENTRANCE WINDOW
         call loss(prt,gair_z,gair_a,gair_thk,gair_dens,velocity,air_loss) 
         total_loss = total_loss + air_loss

* HMS Det. entrance window loss
         call loss(prt,hdet_ent_z,hdet_ent_a,hdet_ent_thk,
     &              hdet_ent_den,velocity,h_win_loss) !HMS window
         total_loss = total_loss + h_win_loss

         e_loss = total_loss

*eloss debug HMS
         if(gelossdebug.ne.0)then
            if(liquid) then
               write(6,10)'liquid',
     &              'back','cell_wall','scat_win','air','HMS_win',
     &              'total'
               write(6,20) back_loss,cell_wall_loss,scat_win_loss,air_loss,
     &              h_win_loss,total_loss
            else
               write(6,30)'solid', 'scat_win','air','HMS_win','total'
               write(6,40) scat_win_loss,air_loss,h_win_loss,total_loss
            endif
            write(6,*)
         endif   

      endif

*************************************
* Now calculate the SOS energy loss.  
*************************************

      if (arm.eq.2) then			! SOS
* 8 mil aluminum scattering chamber window on SOS side
         call loss(prt,sscat_win_z,sscat_win_a,sscat_win_thk,
     &               sscat_win_den,velocity,scat_win_loss) !aluminum
         total_loss = total_loss + scat_win_loss
*ENERGY LOSS IN AIR GAP BEWTEEN THE CHAMBER AND THE ENTRANCE WINDOW
         call loss(prt,gair_z,gair_a,gair_thk,gair_dens,velocity,air_loss) 
         total_loss = total_loss + air_loss

*
* SOS Det. entrance window loss
         call loss(prt,sdet_ent_z,sdet_ent_a,sdet_ent_thk,
     &               sdet_ent_den,velocity,s_win_loss) !SOS window
         total_loss = total_loss + s_win_loss

         e_loss = total_loss

*eloss debug SOS
         if(gelossdebug.ne.0)then
            if(liquid) then
               write(6,10)'liquid',
     &              'back','cell_wall','scat_win','air','SOS_win',
     &              'total'
               write(6,20) back_loss,cell_wall_loss,scat_win_loss,air_loss,
     &              s_win_loss,total_loss
            else
               write(6,30)'solid',
     &               'scat_win','air','SOS_win','total'
               write(6,40) scat_win_loss,air_loss,s_win_loss,total_loss
            endif
            write(6,*) ' '
         endif   

      endif

 100  continue

      RETURN
      END

*-------------------------------------------------------------
      subroutine loss(electron,z,a,thick,dens,velocity,e_loss)
*-------------------------------------------------------------
*-         Prototype C function 
*- 
*-
*-    Purpose and Method :  Calculate energy loss 
*-    
*-    Output: -
*-    Created   1-Dec-1995  Rolf Ent
*-   
*-    Verification:  The non-electron portion on this subr. is Bethe_Bloch
*-                   equation (Physial Review D vol.50 (1994) 1251 with full
*-		     calculation of Tmax and the density correction. The electron
*-		     part has been switched from O'Brien, Phys. Rev. C9(1974)1418,
*-		     to Bethe-Bloch with relativistic corrections and density
*-		     density correction, Leo, Techniques for Nuclear and Particle 
*-		     Physics Experiments
*-                   J. Volmer 8/2/98 16:50
*------------------------------------------------------------------------------*
      IMPLICIT NONE
      SAVE
*
      include 'gen_data_structures.cmn'
      include 'hms_data_structures.cmn'
      include 'sos_data_structures.cmn'
*
      LOGICAL electron
      REAL*4 eloss,z,a,thick,dens,beta,e_loss
      REAL*4 icon_ev,me_ev
      REAL*4 icon_gev,me_gev
      REAL*4 particle
      REAL*4 denscorr,hnup,c0,log10bg,pmass,tmax,gamma,velocity
      REAL*4 tau,betagamma
      parameter (me_ev = 510999.)
      parameter (me_gev = 0.000510999)
*

 91   format(7(A10))
 90   format(7(2x,f8.5))
      e_loss = 0.0
      eloss  = 0.0

*************************************************************************
* for debugging print out all variables that have been passed on tol loss
*************************************************************************

*****************************************************************************
* calculate the mean excitation potential I in a newer parametrization 
* given in W.R. Leo's Techniques for Nuclear and Particle Physics Experiments
*****************************************************************************

*     csa 1/99 -- Note that this code calculates the mean energy loss,
*     not the most probable. This is appropriate for the case (as in
*     Hall C) where the resolution of the measurement is significantly
*     greater than the energy loss.

      if (z.lt.1.5) then
         icon_ev = 21.8
      elseif (z.lt.13) then
         icon_ev = 12.*z+7.
      elseif (z.ge.13) then
         icon_ev = z*(9.76+58.8*z**(-1.19))
      endif
      icon_gev = icon_ev*1.0e-9

**********************************************
* extract the velocity of the particle:
*     hadrons:   velocity = beta
*     electrons: velocity = log_10(beta*gamma)
**********************************************

      if (electron) then
         log10bg=velocity
         betagamma=exp(velocity*log(10.))
         beta=betagamma/(sqrt(1.+betagamma**2))
         gamma=sqrt(1.+betagamma**2)
         tau=gamma-1.
      elseif (.not.electron) then
         beta=abs(velocity)

* we still need some protection from nonsense values for beta

         if (beta.ge.1.) beta=.9995
         if (beta.le..1) beta=.1

         gamma=1./sqrt(1.-beta**2)
         betagamma=beta*gamma
         log10bg=log(betagamma)/log(10.)
         tau=gamma-1.
      endif

******************************************************
* calculate the density correction, as given in Leo,
* with Sternheimer's parametrization
* I is the mean excitation potential of the material
* hnup= h*nu_p is the plasma frequency of the material
******************************************************

      denscorr=0.
      if(A.gt.0.) then
         HNUP=28.816E-9*sqrt(abs(DENS*Z/A))
      else
         HNUP=28.816E-9*sqrt(abs(DENS*Z/1.))
      endif

* log(icon_gev/hnup)=log(icon_gev)-log(hnup)
      C0=-2*(log(icon_gev)-log(hnup)+.5)

      if(log10bg.lt.0.) then
         denscorr=0.
      elseif(log10bg.lt.3.) then
         denscorr=C0+2*log(10.)*log10bg+abs(C0/27.)*(3.-log10bg)**3
      elseif(log10bg.lt.4.7) then
         denscorr=C0+2*log(10.)*log10bg
      else
         denscorr=C0+2*log(10.)*4.7
      endif

*******************************************************************
* for hadrons: calculate the maximum possible energy transfer to an
*              orbital electron, find out what the hadron mass is
*******************************************************************

      pmass=me_gev
      if (.not.electron) then
         pmass=max(hpartmass,spartmass)
         if (pmass.lt.2*me_gev) pmass=0.5
         tmax=abs(2*me_gev*beta**2*gamma**2/
     >        (1+2*abs(gamma)*me_gev/pmass+(me_gev/pmass)**2))
      endif

**********************************************************************       
* now calculate the energy loss for electrons 
**********************************************************************
* electron
      if (electron) then
         if((thick.gt.0.0).and.(dens.gt.0.0).and.(a.gt.0.).and.(beta.gt.0.)
     >       .and.(tau.gt.0).and.(betagamma.gt.0))then
*jv            eloss=0.1535e-03*z/a*thick/beta**2*(
*jv     >           log(tau**2*(tau+2.)/2./(icon_gev/me_gev)**2)
*jv     >           +1-beta**2+(tau**2/8-(2*tau+1)*log(2.))/(tau+1)**2
*jv     >           -(-(2*log(icon_gev/hnup)+1)+2*log(betagamma)))
            eloss=0.1535e-03*z/a*thick/beta**2*(
     >           2*log(tau)+log((tau+2.)/2.)-2*(log(icon_gev)-log(me_gev))
     >           +1-beta**2+(tau**2/8-(2*tau+1)*log(2.))/(tau+1)**2
     >           -(-(2*(log(icon_gev)-log(hnup))+1)+2*log(betagamma)))
         endif

*jv        if(thick.gt.0.0.and.dens.gt.0.0)then
*jv           eloss = 0.1536e-03*z/a*thick*(19.26 + log(thick/dens))
*jv         endif

      endif

********************************************************************      
* now calculate the energy loss for hadrons 
********************************************************************
* proton
      if(.not.electron) then

*jv         icon_ev = 16.*z**0.9
*jv         if (z.lt.1.5) icon_ev = 21.8

         if((thick.gt.0.0).and.(beta.gt.0.0).and.(beta.lt.1.0).and.(a.gt.0.))then

*jv            eloss = 2.*0.1535e-3*Z/A*thick/beta**2*(
*jv     >           .5*log(2*me_gev*beta**2*gamma**2*tmax/icon_gev**2)
*jv     >           -beta**2-denscorr/2.)
            eloss = abs(2.*0.1535e-3*Z/A*thick/beta**2)*(
     >           .5*(log(2*me_gev)+2*log(beta)+2*log(gamma)+log(tmax)-2*log(icon_gev))
     >           -beta**2-denscorr/2.)

*jv          eloss = log(2.*me_ev*beta*beta/icon_ev/(1.-beta*beta))
*jv     &                - beta*beta
*jv          eloss = 2.*0.1536e-03*z/a*thick/beta/beta * eloss

         endif
      endif

      if (eloss.le.0.) write(6,*)'loss: eloss<=0!'
* units should be in GeV
      e_loss = eloss

      if ((gelossdebug.ne.0).or.(eloss.le.0)) then
         particle=0.0
         if (electron) particle=1.0
         write(6,91) 'electron?','ztgt','atgt','thick','dens','velocity','e_loss'
         write(6,90) particle,z,a,thick,dens,velocity,e_loss
         write(6,'(4A10)') 'velocity','beta','pmass','denscorr'
         write(6,'(6(2x,f8.5))') velocity,beta,pmass,denscorr
         write(6,'(6A10)') 'betagamma','log10bg','tau','gamma','icon_ev','hnup (eV)'
         write(6,'(6(2x,F8.3))') betagamma,log10bg,tau,gamma,icon_ev,hnup*1e9
      endif

      RETURN
      END
