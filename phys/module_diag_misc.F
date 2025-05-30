#if ( NMM_CORE == 1)
MODULE module_diag_misc
CONTAINS
   SUBROUTINE diag_misc_stub
   END SUBROUTINE diag_misc_stub
END MODULE module_diag_misc
#else
!WRF:MEDIATION_LAYER:PHYSICS
!

MODULE module_diag_misc
CONTAINS
   SUBROUTINE diagnostic_output_calc(                                 &
                      ids,ide, jds,jde, kds,kde,                      &
                      ims,ime, jms,jme, kms,kme,                      &
                      ips,ipe, jps,jpe, kps,kpe,                      & ! patch  dims
                      i_start,i_end,j_start,j_end,kts,kte,num_tiles   &
                     ,dpsdt,dmudt                                     &
                     ,p8w,pk1m,mu_2,mu_2m                             &
                     ,raincv,rainncv,rainc,rainnc                     &
                     ,i_rainc,i_rainnc                                &
                     ,hfx,sfcevp,lh,t2                                &
                     ,ACSWUPT,ACSWUPTC,ACSWDNT,ACSWDNTC               & ! Optional
                     ,ACSWUPB,ACSWUPBC,ACSWDNB,ACSWDNBC               & ! Optional
                     ,ACLWUPT,ACLWUPTC,ACLWDNT,ACLWDNTC               & ! Optional
                     ,ACLWUPB,ACLWUPBC,ACLWDNB,ACLWDNBC               & ! Optional
                     ,I_ACSWUPT,I_ACSWUPTC,I_ACSWDNT,I_ACSWDNTC       & ! Optional
                     ,I_ACSWUPB,I_ACSWUPBC,I_ACSWDNB,I_ACSWDNBC       & ! Optional
                     ,I_ACLWUPT,I_ACLWUPTC,I_ACLWDNT,I_ACLWDNTC       & ! Optional
                     ,I_ACLWUPB,I_ACLWUPBC,I_ACLWDNB,I_ACLWDNBC       & ! Optional
                     ,athmp, aqvmp                                    &
                     ,athcu, aqvcu, aucu, avcu                        &
                     ,athsh, aqvsh, aush, avsh                        &
                     ,athbl, aqvbl, aubl, avbl                        &
                     ,athralw, athrasw                                &
                     ,h_diabatic, qv_diabatic                         &
                     ,rthcuten, rqvcuten, rucuten, rvcuten            &
                     ,rthshten, rqvshten, rushten, rvshten            &
                     ,rthblten, rqvblten, rublten, rvblten            &
                     ,rthratenlw, rthratensw                          &
                     ,dt,xtime                                        &
                     ,diag_print                                      &
                     ,bucket_mm, bucket_J                             &
                     ,prec_acc_c, prec_acc_nc, snow_acc_nc            &
                     ,snowncv, prec_acc_dt, curr_secs2                &
                     ,history_interval                                &
                     ,itimestep                                       &
                     ,cu_used, shcu_used, acc_phy_tend                &
                                                                      )
!----------------------------------------------------------------------

  USE module_dm, ONLY: wrf_dm_sum_real, wrf_dm_maxval

  IMPLICIT NONE
!======================================================================
! Definitions
!-----------
!-- DIAG_PRINT    print control: 0 - no diagnostics; 1 - dmudt only; 2 - all
!-- DT            time step (second)
!-- XTIME         forecast time
!-- ACSWUPT
!-- ACSWUPTC
!-- ACSWDNT
!-- ACSWDNTC
!-- ACSWUPB
!-- ACSWUPBC
!-- ACSWDNB
!-- ACSWDNBC
!-- ACLWUPT
!-- ACLWUPTC
!-- ACLWDNT
!-- ACLWDNTC
!-- ACLWUPB
!-- ACLWUPBC
!-- ACLWDNB
!-- ACLWDNBC
!-- ATHMPTEN      Accumulated theta tendency from microphysics
!-- AQVMPTEN      Accumulated qv tendency from microphysics
!-- ATHCUTEN      Accumulated theta tendency from cumulus physics
!-- AQVCUTEN      Accumulated qv tendency from cumulus physics
!-- AUCUTEN       Accumulated u-wind tendency from cumulus physics
!-- AVCUTEN       Accumulated v-wind tendency from cumulus physics
!-- ATHSHTEN      Accumulated theta tendency from shallow cumulus
!-- AQVSHTEN      Accumulated qv tendency from shallow cumulus
!-- AUSHTEN       Accumulated u-wind tendency from shallow cumulus
!-- AVSHTEN       Accumulated v-wind tendency from shallow cumulus
!-- ATHBLTEN      Accumulated theta tendency from pbl physics
!-- AQVBLTEN      Accumulated qv tendency from pbl physics
!-- AUBLTEN       Accumulated u-wind tendency from pbl physics
!-- AVBLTEN       Accumulated v-wind tendency from pbl physics
!-- ATHRATENLW    Accumulated theta tendency from longwave radiation
!-- ATHRATENSW    Accumulated theta tendency from shortwave radiation
!-- P8W           3D pressure array at full eta levels
!-- MU            dry column hydrostatic pressure
!-- RAINC         cumulus scheme precipitation since hour 0
!-- RAINCV        cumulus scheme precipitation in one time step (mm)
!-- RAINNC        explicit scheme precipitation since hour 0
!-- RAINNCV       explicit scheme precipitation in one time step (mm)
!-- SNOWNCV       explicit scheme snow in one time step (mm)
!-- HFX           surface sensible heat flux
!-- LH            surface latent heat flux
!-- SFCEVP        total surface evaporation
!-- PREC_ACC_C    accumulated convective precip over accumulation time prec_acc_dt
!-- PREC_ACC_NC   accumulated explicit precip over accumulation time prec_acc_dt
!-- SNOW_ACC_NC   accumulated explicit snow precip over accumulation time prec_acc_dt
!-- PREC_ACC_DT   precip accumulation time, default is 60 min
!-- CURR_SECS2    Time (s) since the beginning of the restart
!
!-- ids           start index for i in domain
!-- ide           end index for i in domain
!-- jds           start index for j in domain
!-- jde           end index for j in domain
!-- kds           start index for k in domain
!-- kde           end index for k in domain
!-- ims           start index for i in memory
!-- ime           end index for i in memory
!-- jms           start index for j in memory
!-- jme           end index for j in memory
!-- ips           start index for i in patch
!-- ipe           end index for i in patch
!-- jps           start index for j in patch
!-- jpe           end index for j in patch
!-- kms           start index for k in memory
!-- kme           end index for k in memory
!-- i_start       start indices for i in tile
!-- i_end         end indices for i in tile
!-- j_start       start indices for j in tile
!-- j_end         end indices for j in tile
!-- kts           start index for k in tile
!-- kte           end index for k in tile
!-- num_tiles     number of tiles
!
!======================================================================

   INTEGER,      INTENT(IN   )    ::                             &
                                      ids,ide, jds,jde, kds,kde, &
                                      ims,ime, jms,jme, kms,kme, &
                                      ips,ipe, jps,jpe, kps,kpe, &
                                                        kts,kte, &
                                                      num_tiles

   INTEGER, DIMENSION(num_tiles), INTENT(IN) ::                  &
     &           i_start,i_end,j_start,j_end

   INTEGER,   INTENT(IN   )    ::   diag_print
   REAL,      INTENT(IN   )    ::   bucket_mm, bucket_J

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ),                 &
         INTENT(IN ) ::                                     p8w

   REAL, DIMENSION( ims:ime , jms:jme ), INTENT(IN) ::           &
                                                           MU_2  &
                                                    ,   RAINNCV  &
                                                    ,    RAINCV  &
                                                    ,   SNOWNCV  &
                                                    ,       HFX  &
                                                    ,        LH  &
                                                    ,    SFCEVP  &  
                                                    ,        T2     

   REAL, DIMENSION( ims:ime , jms:jme ),                         &
          INTENT(INOUT) ::                                DPSDT  &
                                                    ,     DMUDT  &
                                                    ,    RAINNC  &
                                                    ,     RAINC  &
                                                    ,     MU_2M  &
                                                    ,      PK1M
 
   REAL,  INTENT(IN   ) :: DT, XTIME
   INTEGER,  INTENT(IN   )  ::  cu_used, shcu_used, acc_phy_tend
   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(INOUT) ::&
                                                    athmp,aqvmp  &
                                         ,athcu,aqvcu,aucu,avcu  &
                                         ,athsh,aqvsh,aush,avsh  &
                                         ,athbl,aqvbl,aubl,avbl  &
                                               ,athralw,athrasw

   REAL, DIMENSION( ims:ime, kms:kme, jms:jme ), INTENT(IN) ::   &
                                         h_diabatic,qv_diabatic  &
                             ,rthcuten,rqvcuten,rucuten,rvcuten  &
                             ,rthshten,rqvshten,rushten,rvshten  &
                             ,rthblten,rqvblten,rublten,rvblten  &
                                         ,rthratenlw,rthratensw

   INTEGER, DIMENSION( ims:ime , jms:jme ), INTENT(INOUT) ::     &
                                                       I_RAINC,  &
                                                       I_RAINNC
   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT) ::&
                      ACSWUPT,ACSWUPTC,ACSWDNT,ACSWDNTC,          &
                      ACSWUPB,ACSWUPBC,ACSWDNB,ACSWDNBC,          &
                      ACLWUPT,ACLWUPTC,ACLWDNT,ACLWDNTC,          &
                      ACLWUPB,ACLWUPBC,ACLWDNB,ACLWDNBC
   INTEGER, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT) ::&
                      I_ACSWUPT,I_ACSWUPTC,I_ACSWDNT,I_ACSWDNTC,  &
                      I_ACSWUPB,I_ACSWUPBC,I_ACSWDNB,I_ACSWDNBC,  &
                      I_ACLWUPT,I_ACLWUPTC,I_ACLWDNT,I_ACLWDNTC,  &
                      I_ACLWUPB,I_ACLWUPBC,I_ACLWDNB,I_ACLWDNBC

   REAL, DIMENSION( ims:ime, jms:jme ), OPTIONAL, INTENT(INOUT) ::&
                      PREC_ACC_C, PREC_ACC_NC, SNOW_ACC_NC

   REAL, OPTIONAL, INTENT(IN)::  PREC_ACC_DT, CURR_SECS2

   INTEGER :: i,j,k,its,ite,jts,jte,ij
   INTEGER :: idp,jdp,irc,jrc,irnc,jrnc,isnh,jsnh

   REAL              :: no_points
   REAL              :: dpsdt_sum, dmudt_sum, dardt_sum, drcdt_sum, drndt_sum
   REAL              :: hfx_sum, lh_sum, sfcevp_sum, rainc_sum, rainnc_sum, raint_sum
   REAL              :: dmumax, raincmax, rainncmax, snowhmax
   LOGICAL, EXTERNAL :: wrf_dm_on_monitor
   CHARACTER*256     :: outstring
   CHARACTER*6       :: grid_str

   INTEGER, INTENT(IN) ::                                        &
                                     history_interval,itimestep

   INTEGER :: idump

!-----------------------------------------------------------------
! Compute physics tendency accumulations in a given time window

   IF ( acc_phy_tend .gt. 0 ) THEN

!  !$OMP PARALLEL DO   &
!  !$OMP PRIVATE ( ij )
   DO ij = 1 , num_tiles

      IF (mod(curr_secs2, history_interval*60.) == 0.) THEN
         WRITE(outstring,*) 'Reseting accumulation to 0'
         CALL wrf_debug ( 10, TRIM(outstring) )
         DO j=j_start(ij),j_end(ij)
         DO k=kps,kpe
         DO i=i_start(ij),i_end(ij)
            athmp(i,k,j) = 0.
            aqvmp(i,k,j) = 0.
            IF ( cu_used == 1 ) THEN
            athcu(i,k,j) = 0.
            aqvcu(i,k,j) = 0.
             aucu(i,k,j) = 0.
             avcu(i,k,j) = 0.
            END IF
            IF ( shcu_used == 1 ) THEN
            athsh(i,k,j) = 0.
            aqvsh(i,k,j) = 0.
             aush(i,k,j) = 0.
             avsh(i,k,j) = 0.
            END IF
            athbl(i,k,j) = 0.
            aqvbl(i,k,j) = 0.
             aubl(i,k,j) = 0.
             avbl(i,k,j) = 0.
          athralw(i,k,j) = 0.
          athrasw(i,k,j) = 0.
         ENDDO
         ENDDO
         ENDDO
      ENDIF
      DO j=j_start(ij),j_end(ij)
      DO k=kps,kpe
      DO i=i_start(ij),i_end(ij)
         athmp(i,k,j)  = athmp(i,k,j)  +  h_diabatic(i,k,j)*dt
         aqvmp(i,k,j)  = aqvmp(i,k,j)  +  qv_diabatic(i,k,j)*dt
         IF ( cu_used == 1 ) THEN
         athcu(i,k,j)  = athcu(i,k,j)  +  rthcuten(i,k,j)*dt
         aqvcu(i,k,j)  = aqvcu(i,k,j)  +  rqvcuten(i,k,j)*dt
          aucu(i,k,j)  =  aucu(i,k,j)  +  rucuten(i,k,j)*dt
          avcu(i,k,j)  =  avcu(i,k,j)  +  rvcuten(i,k,j)*dt
         END IF
         IF ( shcu_used == 1 ) THEN
         athsh(i,k,j)  = athsh(i,k,j)  +  rthshten(i,k,j)*dt
         aqvsh(i,k,j)  = aqvsh(i,k,j)  +  rqvshten(i,k,j)*dt
          aush(i,k,j)  =  aush(i,k,j)  +  rushten(i,k,j)*dt
          avsh(i,k,j)  =  avsh(i,k,j)  +  rvshten(i,k,j)*dt
         END IF
         athbl(i,k,j)  = athbl(i,k,j)  +  rthblten(i,k,j)*dt
         aqvbl(i,k,j)  = aqvbl(i,k,j)  +  rqvblten(i,k,j)*dt
          aubl(i,k,j)  =  aubl(i,k,j)  +  rublten(i,k,j)*dt
          avbl(i,k,j)  =  avbl(i,k,j)  +  rvblten(i,k,j)*dt
       athralw(i,k,j)  =  athralw(i,k,j)  +  rthratenlw(i,k,j)*dt
       athrasw(i,k,j)  =  athrasw(i,k,j)  +  rthratensw(i,k,j)*dt
      ENDDO
      ENDDO
      ENDDO
    ENDDO
   ENDIF

!-----------------------------------------------------------------
! Handle accumulations with buckets to prevent round-off truncation in long runs
! This is done every 360 minutes assuming time step fits exactly into 360 minutes

!!!~~ CURR_SECS2 is elapsed seconds since restart. It is preferred to
!!!~~ XTIME here because XTIME goes imprecise at 2^24, just under 32 years.

   IF(bucket_mm .gt. 0. .AND. MOD(NINT(CURR_SECS2),3600) .EQ. 0)THEN
! SET START AND END POINTS FOR TILES
!  !$OMP PARALLEL DO   &
!  !$OMP PRIVATE ( ij )

   DO ij = 1 , num_tiles

      IF (xtime .eq. 0.0)THEN
        DO j=j_start(ij),j_end(ij)
        DO i=i_start(ij),i_end(ij)
          i_rainnc(i,j) = 0
          i_rainc(i,j) = 0
        ENDDO      
        ENDDO
      ENDIF
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
        IF(rainnc(i,j) .gt. bucket_mm)THEN
          rainnc(i,j) = rainnc(i,j) - bucket_mm
          i_rainnc(i,j) =  i_rainnc(i,j) + 1
        ENDIF
        IF(rainc(i,j) .gt. bucket_mm)THEN
          rainc(i,j) = rainc(i,j) - bucket_mm
          i_rainc(i,j) =  i_rainc(i,j) + 1
        ENDIF
      ENDDO      
      ENDDO

      IF (xtime .eq. 0.0 .and. bucket_J .gt. 0.0 .and. PRESENT(ACSWUPT))THEN
        DO j=j_start(ij),j_end(ij)
        DO i=i_start(ij),i_end(ij)
          i_acswupt(i,j) = 0
          i_acswuptc(i,j) = 0
          i_acswdnt(i,j) = 0
          i_acswdntc(i,j) = 0
          i_acswupb(i,j) = 0
          i_acswupbc(i,j) = 0
          i_acswdnb(i,j) = 0
          i_acswdnbc(i,j) = 0
        ENDDO      
        ENDDO
      ENDIF
      IF (xtime .eq. 0.0  .and. bucket_J .gt. 0.0 .and. PRESENT(ACLWUPT))THEN
        DO j=j_start(ij),j_end(ij)
        DO i=i_start(ij),i_end(ij)
          i_aclwupt(i,j) = 0
          i_aclwuptc(i,j) = 0
          i_aclwdnt(i,j) = 0
          i_aclwdntc(i,j) = 0
          i_aclwupb(i,j) = 0
          i_aclwupbc(i,j) = 0
          i_aclwdnb(i,j) = 0
          i_aclwdnbc(i,j) = 0
        ENDDO      
        ENDDO
      ENDIF
      IF (PRESENT(ACSWUPT) .and. bucket_J .gt. 0.0)THEN
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
        IF(acswupt(i,j) .gt. bucket_J)THEN
          acswupt(i,j) = acswupt(i,j) - bucket_J
          i_acswupt(i,j) =  i_acswupt(i,j) + 1
        ENDIF
        IF(acswuptc(i,j) .gt. bucket_J)THEN
          acswuptc(i,j) = acswuptc(i,j) - bucket_J
          i_acswuptc(i,j) =  i_acswuptc(i,j) + 1
        ENDIF
        IF(acswdnt(i,j) .gt. bucket_J)THEN
          acswdnt(i,j) = acswdnt(i,j) - bucket_J
          i_acswdnt(i,j) =  i_acswdnt(i,j) + 1
        ENDIF
        IF(acswdntc(i,j) .gt. bucket_J)THEN
          acswdntc(i,j) = acswdntc(i,j) - bucket_J
          i_acswdntc(i,j) =  i_acswdntc(i,j) + 1
        ENDIF
        IF(acswupb(i,j) .gt. bucket_J)THEN
          acswupb(i,j) = acswupb(i,j) - bucket_J
          i_acswupb(i,j) =  i_acswupb(i,j) + 1
        ENDIF
        IF(acswupbc(i,j) .gt. bucket_J)THEN
          acswupbc(i,j) = acswupbc(i,j) - bucket_J
          i_acswupbc(i,j) =  i_acswupbc(i,j) + 1
        ENDIF
        IF(acswdnb(i,j) .gt. bucket_J)THEN
          acswdnb(i,j) = acswdnb(i,j) - bucket_J
          i_acswdnb(i,j) =  i_acswdnb(i,j) + 1
        ENDIF
        IF(acswdnbc(i,j) .gt. bucket_J)THEN
          acswdnbc(i,j) = acswdnbc(i,j) - bucket_J
          i_acswdnbc(i,j) =  i_acswdnbc(i,j) + 1
        ENDIF
      ENDDO      
      ENDDO
      ENDIF
      IF (PRESENT(ACLWUPT) .and. bucket_J .gt. 0.0)THEN
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
        IF(aclwupt(i,j) .gt. bucket_J)THEN
          aclwupt(i,j) = aclwupt(i,j) - bucket_J
          i_aclwupt(i,j) =  i_aclwupt(i,j) + 1
        ENDIF
        IF(aclwuptc(i,j) .gt. bucket_J)THEN
          aclwuptc(i,j) = aclwuptc(i,j) - bucket_J
          i_aclwuptc(i,j) =  i_aclwuptc(i,j) + 1
        ENDIF
        IF(aclwdnt(i,j) .gt. bucket_J)THEN
          aclwdnt(i,j) = aclwdnt(i,j) - bucket_J
          i_aclwdnt(i,j) =  i_aclwdnt(i,j) + 1
        ENDIF
        IF(aclwdntc(i,j) .gt. bucket_J)THEN
          aclwdntc(i,j) = aclwdntc(i,j) - bucket_J
          i_aclwdntc(i,j) =  i_aclwdntc(i,j) + 1
        ENDIF
        IF(aclwupb(i,j) .gt. bucket_J)THEN
          aclwupb(i,j) = aclwupb(i,j) - bucket_J
          i_aclwupb(i,j) =  i_aclwupb(i,j) + 1
        ENDIF
        IF(aclwupbc(i,j) .gt. bucket_J)THEN
          aclwupbc(i,j) = aclwupbc(i,j) - bucket_J
          i_aclwupbc(i,j) =  i_aclwupbc(i,j) + 1
        ENDIF
        IF(aclwdnb(i,j) .gt. bucket_J)THEN
          aclwdnb(i,j) = aclwdnb(i,j) - bucket_J
          i_aclwdnb(i,j) =  i_aclwdnb(i,j) + 1
        ENDIF
        IF(aclwdnbc(i,j) .gt. bucket_J)THEN
          aclwdnbc(i,j) = aclwdnbc(i,j) - bucket_J
          i_aclwdnbc(i,j) =  i_aclwdnbc(i,j) + 1
        ENDIF
      ENDDO      
      ENDDO
      ENDIF
   ENDDO
!  !$OMP END PARALLEL DO
   ENDIF

! Compute precipitation accumulation in a given time window: prec_acc_dt
   IF (prec_acc_dt .gt. 0.) THEN

!  !$OMP PARALLEL DO   &
!  !$OMP PRIVATE ( ij )

   DO ij = 1 , num_tiles

      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         IF (mod(curr_secs2, 60.* prec_acc_dt) == 0.) THEN
            prec_acc_c(i,j)  = 0.
            prec_acc_nc(i,j) = 0.
            snow_acc_nc(i,j)  = 0.
         ENDIF
         prec_acc_c(i,j)  = prec_acc_c(i,j)  +  RAINCV(i,j)
         prec_acc_nc(i,j) = prec_acc_nc(i,j) + RAINNCV(i,j)
         prec_acc_c(i,j)  = MAX (prec_acc_c(i,j), 0.0)
         prec_acc_nc(i,j) = MAX (prec_acc_nc(i,j), 0.0)
         snow_acc_nc(i,j)   = snow_acc_nc(i,j) + SNOWNCV(I,J)
! add convective precip to snow bucket if t2 < 273.15
         IF ( t2(i,j) .lt. 273.15 ) THEN
         snow_acc_nc(i,j)   = snow_acc_nc(i,j) +  RAINCV(i,j)
         snow_acc_nc(i,j)   = MAX (snow_acc_nc(i,j), 0.0)
         ENDIF
      ENDDO     
      ENDDO     

   ENDDO     

!  !$OMP END PARALLEL DO
   ENDIF

   if (diag_print .eq. 0 ) return

   IF ( xtime .ne. 0. ) THEN

! COMPUTE THE NUMBER OF MASS GRID POINTS
   no_points = float((ide-ids)*(jde-jds))

! SET START AND END POINTS FOR TILES
!  !$OMP PARALLEL DO   &
!  !$OMP PRIVATE ( ij )

   dmumax = 0.
   DO ij = 1 , num_tiles

!     print *, i_start(ij),i_end(ij),j_start(ij),j_end(ij)
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         dpsdt(i,j)=(p8w(i,kms,j)-pk1m(i,j))/dt
         dmudt(i,j)=(mu_2(i,j)-mu_2m(i,j))/dt
         if(abs(dmudt(i,j)*dt).gt.dmumax)then
           dmumax=abs(dmudt(i,j)*dt)
           idp=i
           jdp=j
         endif
      ENDDO      
      ENDDO

   ENDDO
!  !$OMP END PARALLEL DO

! convert DMUMAX from (PA) to (bars) per time step
   dmumax = dmumax*1.e-5
! compute global MAX
   CALL wrf_dm_maxval ( dmumax,  idp, jdp )

!  print *, 'p8w(30,1,30),pk1m(30,30) : ', p8w(30,1,30),pk1m(30,30)
!  print *, 'mu_2(30,30),mu_2m(30,30) : ', mu_2(30,30),mu_2m(30,30)
   dpsdt_sum = 0.
   dmudt_sum = 0.

   DO j = jps, min(jpe,jde-1)
     DO i = ips, min(ipe,ide-1)
       dpsdt_sum = dpsdt_sum + abs(dpsdt(i,j))
       dmudt_sum = dmudt_sum + abs(dmudt(i,j))
     ENDDO
   ENDDO

! compute global sum
   dpsdt_sum = wrf_dm_sum_real ( dpsdt_sum )
   dmudt_sum = wrf_dm_sum_real ( dmudt_sum )

!  print *, 'dpsdt, dmudt : ', dpsdt_sum, dmudt_sum

   IF ( diag_print .eq. 2 ) THEN
   dardt_sum = 0.
   drcdt_sum = 0.
   drndt_sum = 0.
   rainc_sum = 0.
   raint_sum = 0.
   rainnc_sum = 0.
   sfcevp_sum = 0.
   hfx_sum = 0.
   lh_sum = 0.
   raincmax = 0.
   rainncmax = 0.

   DO j = jps, min(jpe,jde-1)
     DO i = ips, min(ipe,ide-1)
       drcdt_sum = drcdt_sum + abs(raincv(i,j))
       drndt_sum = drndt_sum + abs(rainncv(i,j))
       dardt_sum = dardt_sum + abs(raincv(i,j)) + abs(rainncv(i,j))
       rainc_sum = rainc_sum + abs(rainc(i,j))
! MAX for accumulated conv precip
       IF(rainc(i,j).gt.raincmax)then
          raincmax=rainc(i,j)
          irc=i
          jrc=j
       ENDIF
       rainnc_sum = rainnc_sum + abs(rainnc(i,j))
! MAX for accumulated resolved precip
       IF(rainnc(i,j).gt.rainncmax)then
          rainncmax=rainnc(i,j)
          irnc=i
          jrnc=j
       ENDIF
       raint_sum = raint_sum + abs(rainc(i,j)) + abs(rainnc(i,j))
       sfcevp_sum = sfcevp_sum + abs(sfcevp(i,j))
       hfx_sum = hfx_sum + abs(hfx(i,j))
       lh_sum = lh_sum + abs(lh(i,j))
     ENDDO
   ENDDO

! compute global MAX
   CALL wrf_dm_maxval ( raincmax, irc, jrc )
   CALL wrf_dm_maxval ( rainncmax, irnc, jrnc )

! compute global sum
   drcdt_sum = wrf_dm_sum_real ( drcdt_sum )
   drndt_sum = wrf_dm_sum_real ( drndt_sum )
   dardt_sum = wrf_dm_sum_real ( dardt_sum )
   rainc_sum = wrf_dm_sum_real ( rainc_sum )
   rainnc_sum = wrf_dm_sum_real ( rainnc_sum )
   raint_sum = wrf_dm_sum_real ( raint_sum )
   sfcevp_sum = wrf_dm_sum_real ( sfcevp_sum )
   hfx_sum = wrf_dm_sum_real ( hfx_sum )
   lh_sum = wrf_dm_sum_real ( lh_sum )

   ENDIF

! print out the average values

   CALL get_current_grid_name( grid_str )

#ifdef DM_PARALLEL
   IF ( wrf_dm_on_monitor() ) THEN
#endif
     WRITE(outstring,*) grid_str,'Domain average of dpsdt, dmudt (mb/3h): ', xtime, &
           dpsdt_sum/no_points*108., &
           dmudt_sum/no_points*108.
     CALL wrf_message ( TRIM(outstring) )

     WRITE(outstring,*) grid_str,'Max mu change time step: ', idp,jdp,dmumax
     CALL wrf_message ( TRIM(outstring) )

     IF ( diag_print .eq. 2) THEN
     WRITE(outstring,*) grid_str,'Domain average of dardt, drcdt, drndt (mm/sec): ', xtime, &
           dardt_sum/dt/no_points, &
           drcdt_sum/dt/no_points, &
           drndt_sum/dt/no_points
     CALL wrf_message ( TRIM(outstring) )
     WRITE(outstring,*) grid_str,'Domain average of rt_sum, rc_sum, rnc_sum (mm): ', xtime, &
           raint_sum/no_points, &
           rainc_sum/no_points, &
           rainnc_sum/no_points
     CALL wrf_message ( TRIM(outstring) )
     WRITE(outstring,*) grid_str,'Max Accum Resolved Precip,   I,J  (mm): '               ,&
           rainncmax,irnc,jrnc
     CALL wrf_message ( TRIM(outstring) )
     WRITE(outstring,*) grid_str,'Max Accum Convective Precip,   I,J  (mm): '             ,&
           raincmax,irc,jrc
     CALL wrf_message ( TRIM(outstring) )
     WRITE(outstring,*) grid_str,'Domain average of sfcevp, hfx, lh: ', xtime, &
           sfcevp_sum/no_points, &
           hfx_sum/no_points, &
           lh_sum/no_points
     CALL wrf_message ( TRIM(outstring) )
     ENDIF
#ifdef DM_PARALLEL
   ENDIF
#endif

   ENDIF

! save values at this time step
   !$OMP PARALLEL DO   &
   !$OMP PRIVATE ( ij,i,j )
   DO ij = 1 , num_tiles

      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         pk1m(i,j)=p8w(i,kms,j)
         mu_2m(i,j)=mu_2(i,j)
      ENDDO
      ENDDO

      IF ( xtime .lt. 0.0001 ) THEN
      DO j=j_start(ij),j_end(ij)
      DO i=i_start(ij),i_end(ij)
         dpsdt(i,j)=0.
         dmudt(i,j)=0.
      ENDDO
      ENDDO
      ENDIF

   ENDDO
   !$OMP END PARALLEL DO

   END SUBROUTINE diagnostic_output_calc


!-------------------------- NOAHMP model diagnostic output
   subroutine noahmp_output_calc(  ims,ime, jms,jme                                  ,&
      i_start  ,i_end    ,j_start  ,j_end    ,num_tiles                              ,&
      dt       ,noahmp_acc_dt      ,curr_secs2,opt_run  ,stepwtd ,itimestep          ,&
      acsagv   ,acsagb   ,acirg    ,acshg    ,acevg     ,acghv   ,acpahg   ,acirb    ,&
      acshb    ,acevb    ,acghb    ,acpahb   ,acsav     ,acirc   ,acshc    ,acevc    ,&
      actr     ,acpahv   ,acswdnlsm,acswuplsm,                                        &
      aclwdnlsm,aclwuplsm,acshflsm ,aclhflsm ,acghflsm  ,acpahlsm,acints   ,acintr   ,&
      acdrips  ,acdripr  ,acthros  ,acthror  ,acetlsm   ,acsnmelt,                    &
      acsnsub  ,acsnfro  ,acsubc   ,acfroc   ,acevac    ,acdewc  ,acfrzc   ,acmeltc  ,&
      acsnbot  ,acponding,acrainlsm,acsnowlsm,acrainsnow,acrunsb ,acrunsf  ,isnow    ,&
      acqlat   ,acqrf  ,acrech ,acqspring ,acecan ,acetran ,acedir ,aceflxb ,accanhs ,&
      sag      ,irg      ,shg      ,evg      ,ghv       ,pahg    ,irb      ,shb      ,&
      evb      ,ghb      ,pahb     ,sav      ,ircmp     ,shc     ,evc      ,tr       ,&
      pahv     ,swdown   ,albedo   ,emiss    ,                                        &
      glw      ,trad     ,qints    ,qintr    ,qdrips    ,qdripr  ,qthros   ,qthror   ,&
      qsnsub   ,qsnfro   ,qsubc    ,qfroc    ,qevac     ,qdewc   ,qfrzc    ,qmeltc   ,&
      qsnbot   ,ponding  ,rainlsm  ,snowlsm  ,runsb     ,runsf   ,fpice    ,fveg     ,&
      qlat     ,qrf      ,deeprech ,qspring  ,ecan      ,etran   ,edir     ,eflxb    ,&
      canhs    ,qmelt    )

!----------------------------------------------------------------------

   implicit none

!======================================================================

   integer,      intent(in   )    ::  ims,ime, jms,jme, num_tiles

   integer, dimension(num_tiles), intent(in) :: i_start,i_end,j_start,j_end

   real   ,           intent(in) :: dt
   real   , optional, intent(in) :: noahmp_acc_dt, curr_secs2
   integer, optional, intent(in) :: opt_run, stepwtd, itimestep

   real, dimension( ims:ime, jms:jme ), optional, intent(inout) ::                    &
      acsagv   ,acsagb   ,acirg    ,acshg    ,acevg     ,acghv   ,acpahg   ,acirb    ,&
      acshb    ,acevb    ,acghb    ,acpahb   ,acsav     ,acirc   ,acshc    ,acevc    ,&
      actr     ,acpahv   ,acswdnlsm,acswuplsm,                                        &
      aclwdnlsm,aclwuplsm,acshflsm ,aclhflsm ,acghflsm  ,acpahlsm,acints   ,acintr   ,&
      acdrips   ,acdripr ,acthros  ,acthror  ,acetlsm   ,acsnmelt,                    &
      acsnsub  ,acsnfro  ,acsubc   ,acfroc   ,acevac    ,acdewc  ,acfrzc   ,acmeltc  ,&
      acsnbot  ,acponding,acrainlsm,acsnowlsm,acrainsnow,acrunsb ,acrunsf  ,          &
      acqlat   ,acqrf    ,acrech   ,acqspring,acecan    ,acetran ,acedir   ,aceflxb  ,&
      accanhs

   real, dimension( ims:ime, jms:jme ), optional, intent(in) ::                       &
      sag      ,irg      ,shg      ,evg      ,ghv       ,pahg    ,irb      ,shb      ,&
      evb      ,ghb      ,pahb     ,sav      ,ircmp     ,shc     ,evc      ,tr       ,&
      pahv     ,swdown   ,albedo   ,emiss    ,                                        &
      glw      ,trad     ,qints    ,qintr    ,qdrips    ,qdripr  ,qthros   ,qthror   ,&
      qsnsub   ,qsnfro   ,qsubc    ,qfroc    ,qevac     ,qdewc   ,qfrzc    ,qmeltc   ,&
      qsnbot   ,ponding  ,rainlsm  ,snowlsm  ,runsb     ,runsf   ,fpice    ,fveg     ,&
      qlat     ,qrf      ,deeprech ,qspring  ,ecan      ,etran   ,edir     ,eflxb    ,&
      canhs    ,qmelt

   integer, dimension( ims:ime, jms:jme ), optional, intent(in) ::   isnow

   integer :: i,j,ij
   real :: kjconvert

! compute noah-mp accumulation in a given time window: noahmp_acc_dt

   if (noahmp_acc_dt .gt. 0.) then

!  !$omp parallel do   &
!  !$omp private ( ij )

   do ij = 1 , num_tiles

      do j=j_start(ij),j_end(ij)
      do i=i_start(ij),i_end(ij)
         if (mod(curr_secs2, 60.* noahmp_acc_dt) == 0.) then
            acsagb(i,j) = 0.
            acsagv(i,j) = 0.
            acirg(i,j)  = 0.
            acshg(i,j)  = 0.
            acevg(i,j)  = 0.
            acghv(i,j)  = 0.
            acpahg(i,j) = 0.
            acirb(i,j)  = 0.
            acshb(i,j)  = 0.
            acevb(i,j)  = 0.
            acghb(i,j)  = 0.
            acpahb(i,j) = 0.
            acsav(i,j)  = 0.
            acirc(i,j)  = 0.
            acshc(i,j)  = 0.
            acevc(i,j)  = 0.
            actr (i,j)  = 0.
            acpahv(i,j) = 0.
            accanhs(i,j)= 0.
            acswdnlsm(i,j)  = 0.
            acswuplsm(i,j)  = 0.
            aclwdnlsm(i,j)  = 0.
            aclwuplsm(i,j)  = 0.
            acshflsm(i,j)   = 0.
            aclhflsm(i,j)   = 0.
            acghflsm(i,j)   = 0.
            acpahlsm(i,j)   = 0.
            acints(i,j)     = 0.
            acintr(i,j)     = 0.
            acdrips(i,j)    = 0.
            acdripr(i,j)    = 0.
            acthros(i,j)    = 0.
            acthror(i,j)    = 0.
            acsnsub(i,j)    = 0.
            acsnfro(i,j)    = 0.
            acsubc(i,j)     = 0.
            acfroc(i,j)     = 0.
            acevac(i,j)     = 0.
            acdewc(i,j)     = 0.
            acfrzc(i,j)     = 0.
            acmeltc(i,j)    = 0.
            acsnbot(i,j)    = 0.
            acsnmelt(i,j)   = 0.
            acrunsf(i,j)    = 0.
            acrunsb(i,j)    = 0.
            acecan(i,j)     = 0.
            acetran(i,j)    = 0.
            acedir(i,j)     = 0.
            acetlsm(i,j)    = 0.
            aceflxb(i,j)    = 0.
            acponding(i,j)  = 0.
            acrainsnow(i,j) = 0.
            acrainlsm(i,j)  = 0.
            acsnowlsm(i,j)  = 0.
            acqlat(i,j)     = 0.
            acqrf(i,j)      = 0.
            acrech(i,j)     = 0.
            acqspring(i,j)  = 0.
         endif

         kjconvert = dt / 1000.0
         acsagb(i,j) = acsagb(i,j) +  kjconvert * (1.0 - fveg(i,j)) * sag(i,j)
         acsagv(i,j) = acsagv(i,j) +  kjconvert * fveg(i,j) * sag(i,j)
         acirg(i,j)  = acirg(i,j)  +  kjconvert * fveg(i,j) * irg(i,j)
         acshg(i,j)  = acshg(i,j)  +  kjconvert * fveg(i,j) * shg(i,j)
         acevg(i,j)  = acevg(i,j)  +  kjconvert * fveg(i,j) * evg(i,j)
         acghv(i,j)  = acghv(i,j)  +  kjconvert * fveg(i,j) * ghv(i,j)
         acpahg(i,j) = acpahg(i,j) +  kjconvert * fveg(i,j) * pahg(i,j)
         acirb(i,j)  = acirb(i,j)  +  kjconvert * (1.0 - fveg(i,j)) * irb(i,j)
         acshb(i,j)  = acshb(i,j)  +  kjconvert * (1.0 - fveg(i,j)) * shb(i,j)
         acevb(i,j)  = acevb(i,j)  +  kjconvert * (1.0 - fveg(i,j)) * evb(i,j)
         acghb(i,j)  = acghb(i,j)  +  kjconvert * (1.0 - fveg(i,j)) * ghb(i,j)
         acpahb(i,j) = acpahb(i,j) +  kjconvert * (1.0 - fveg(i,j)) * pahb(i,j)
         acsav(i,j)  = acsav(i,j)  +  kjconvert * sav(i,j)
         acirc(i,j)  = acirc(i,j)  +  kjconvert * ircmp(i,j)
         acshc(i,j)  = acshc(i,j)  +  kjconvert * shc(i,j)
         acevc(i,j)  = acevc(i,j)  +  kjconvert * evc(i,j)
         actr(i,j)   = actr(i,j)   +  kjconvert * tr(i,j)
         aceflxb(i,j)= aceflxb(i,j)+  eflxb(i,j) / 1000.0   ! multiplied by dt_soil in ENERGY
         accanhs(i,j)= accanhs(i,j)+  kjconvert * canhs(i,j)
         acpahv(i,j) = acpahv(i,j) +  kjconvert * pahv(i,j)
         acswdnlsm(i,j)  = acswdnlsm(i,j)  +  kjconvert * swdown(i,j)
         acswuplsm(i,j)  = acswuplsm(i,j)  +  kjconvert * swdown(i,j)*albedo(i,j)
         aclwdnlsm(i,j)  = aclwdnlsm(i,j)  +  kjconvert * glw(i,j)*emiss(i,j)
         aclwuplsm(i,j)  = aclwuplsm(i,j)  +  kjconvert * 5.67e-08*emiss(i,j)*trad(i,j)*trad(i,j)*trad(i,j)*trad(i,j)
         acshflsm(i,j)   = acshg(i,j) + acshc(i,j) + acshb(i,j)
         aclhflsm(i,j)   = acevg(i,j) + acevc(i,j) + actr(i,j) + acevb(i,j)
         acghflsm(i,j)   = acghv(i,j) + acghb(i,j)
         acpahlsm(i,j)   = acpahv(i,j) + acpahg(i,j) + acpahb(i,j)
         acints(i,j)     = acints(i,j)     +  dt *   qints(i,j)
         acintr(i,j)     = acintr(i,j)     +  dt *   qintr(i,j)
         acdrips(i,j)    = acdrips(i,j)    +  dt *  qdrips(i,j)
         acdripr(i,j)    = acdripr(i,j)    +  dt *  qdripr(i,j)
         acthros(i,j)    = acthros(i,j)    +  dt *  qthros(i,j)
         acthror(i,j)    = acthror(i,j)    +  dt *  qthror(i,j)
         acsnsub(i,j)    = acsnsub(i,j)    +  dt *  qsnsub(i,j)
         acsnfro(i,j)    = acsnfro(i,j)    +  dt *  qsnfro(i,j)
         acsubc(i,j)     = acsubc(i,j)     +  dt *   qsubc(i,j)
         acfroc(i,j)     = acfroc(i,j)     +  dt *   qfroc(i,j)
         acevac(i,j)     = acevac(i,j)     +  dt *   qevac(i,j)
         acdewc(i,j)     = acdewc(i,j)     +  dt *   qdewc(i,j)
         acfrzc(i,j)     = acfrzc(i,j)     +  dt *   qfrzc(i,j)
         acmeltc(i,j)    = acmeltc(i,j)    +  dt *  qmeltc(i,j)
         acsnbot(i,j)    = acsnbot(i,j)    +  dt *  qsnbot(i,j)
         acsnmelt(i,j)   = acsnmelt(i,j)   +  dt *   qmelt(i,j)
         acrunsf(i,j)    = acrunsf(i,j)    +  runsf(i,j)  ! multiplied by dt_soil in WATER
         acrunsb(i,j)    = acrunsb(i,j)    +  runsb(i,j)  ! multiplied by dt_soil in WATER
         acecan(i,j)     = acecan(i,j)     +  dt *    ecan(i,j)
         acetran(i,j)    = acetran(i,j)    +  dt *   etran(i,j)
         acedir(i,j)     = acedir(i,j)     +  dt *    edir(i,j)
         acetlsm(i,j)    = acetlsm(i,j)    +  dt *   (etran(i,j) + edir(i,j) + ecan(i,j))
         acponding(i,j)  = acponding(i,j)  +       ponding(i,j)
         acrainlsm(i,j)  = acrainlsm(i,j)  +  dt *  rainlsm(i,j)
         acsnowlsm(i,j)  = acsnowlsm(i,j)  +  dt *  snowlsm(i,j)
         if(opt_run == 5) then
           if(mod(itimestep,stepwtd) == 0) then
             acqlat(i,j)     = acqlat(i,j)     +          qlat(i,j) * 1000.0
             acqrf(i,j)      = acqrf(i,j)      +           qrf(i,j) * 1000.0
             acrech(i,j)     = acrech(i,j)     +      deeprech(i,j)
             acqspring(i,j)  = acqspring(i,j)  +       qspring(i,j)
           endif
         endif
         if(isnow(i,j) < 0 .and. isnow(i,j) > -5) then
            acrainsnow(i,j) =  acrainsnow(i,j) + dt * (qdripr(i,j) + qthror(i,j))
         endif
      enddo
      enddo

   enddo

!  !$omp end parallel do
   endif

   end subroutine noahmp_output_calc


END MODULE module_diag_misc
#endif
