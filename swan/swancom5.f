!
!     SWAN/COMPU    file 5 of 5
!
!
!     PROGRAM SWANCOM5.FOR
!
!     This file SWANCOM5 of the main program SWAN
!     includes the next subroutines (mainly subroutines for
!     the propagation in x,y,s,d space and parameters ) :
!
!     SWGEOM  ( determines geometric quantities )
!     SWPSEL  ( determine spectral counters in presence
!               or absence of a current )
!     SPROXY  ( compute spatial propagation velocities CAX, CAY )
!     SPROSD  ( compute spectral propagation velocities CAS, CAD )
!     DSPHER  ( compute Ctheta for propagation over the globe )           33.09
!     STRSXY  ( compute derivative in space and time )
!     SORDUP  ( compute spatial derivatives with SORDUP scheme )          33.10
!     SANDL   ( compute spatial derivatives with S&L scheme )             33.08
!     STRSSI  ( compute derivative in s-space implicit scheme )
!     STRSSB  ( compute derivative in s-space explicit scheme and
!               remove (or dissipate bin's that are blocked) )
!     STRSD   ( compute derivative in d-space implicit )
!     SPREDT  ( calculate action density in central point: first guess )
!     SWAPAR  ( compute wave parameters k, cgo and cg )
!     ADDDIS  ( adds leak and dissipation to arrays in COMPDA, after
!               action densities have been computed )
!     SWFLXD  ( compute derivative in theta-space by means of             40.23
!               flux-limiting )
!     DIFPAR  ( compute diffraction parameter and its derivatives )       40.21
!
!****************************************************************
!
      SUBROUTINE SWGEOM ( RDX, RDY, XCGRID, YCGRID, SWPDIR )
!
!****************************************************************
!
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
      USE M_PARALL
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     40.41: Marcel Zijlema
!     40.98: Marcel Zijlema
!
!  1. Updates
!
!     40.41, Sep. 04: New subroutine (taken from routine SWPSEL)
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     40.98, Feb. 09: SORDUP scheme is made consistent
!
!  2. Purpose
!
!     Determine geometric quantities due to curvilinear grid
!
!  3. Method
!
!     Trivial
!
!  4. Argument variables
!
!     RDX         contains derivatives of (ksi,eta) to x-direction
!                 (i.e. first component of contravariant base
!                  vector RDX(b) = a^(b)_1)
!     RDY         contains derivatives of (ksi,eta) to y-direction
!                 (i.e. second component of contravariant base
!                  vector RDY(b) = a^(b)_2)
!     SWPDIR      sweep direction
!     XCGRID      coordinates of computational grid in x-direction
!     YCGRID      coordinates of computational grid in y-direction
!
      INTEGER SWPDIR
      REAL    XCGRID(MXC,MYC), YCGRID(MXC,MYC),
     &        RDX(MICMAX)    , RDY(MICMAX)
!
!  6. Local variables
!
!     DET   :     determinant or volume of cell
!     DX1   :     first component of covariant base vector a_(1)
!     DX2   :     second component of covariant base vector a_(1)
!     DY1   :     first component of covariant base vector a_(2)
!     DY2   :     second component of covariant base vector a_(2)
!     IC    :     counter
!     IENT  :     number of entries
!     IXY   :     counter
!     VIRT  :     indicates virtual point for 1D mode
!
      INTEGER IC, IENT, IXY
      REAL    VIRT, DET, DX1, DX2, DY1, DY2
!
!  7. Common blocks used
!
!
!  8. Subroutines used
!
!     STRACE           Tracing routine for debugging
!
!  9. Subroutines calling
!
!     SWOMPU
!
! 13. Source text
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'SWGEOM')
!
      IF (KREPTX.GT.0) THEN                                               33.09
!       repeating x-axis (only regular grids)
        IF (SWPDIR.EQ.1 .OR. SWPDIR.EQ.4) THEN
          DX1 = DX * COSPC                                                33.09
          DY1 = DX * SINPC                                                33.09
        ELSE
          DX1 = -DX * COSPC                                               33.09
          DY1 = -DX * SINPC                                               33.09
        ENDIF
        IF ( ONED ) THEN                                                  33.09
!         *** Inclusion of virtual point ***                              33.09
          VIRT = 1.E6                                                     33.09
          IF ( SWPDIR .EQ. 1 .OR. SWPDIR .EQ. 3 ) THEN                    33.09
            DX2 = -VIRT * DY1                                             33.09
            DY2 =  VIRT * DX1                                             33.09
          ELSE                                                            33.09
            DX2 =  VIRT * DY1                                             33.09
            DY2 = -VIRT * DX1                                             33.09
          ENDIF                                                           33.09
        ELSE                                                              33.09
          IF (SWPDIR.LE.2) THEN                                           40.13
            DX2 = - DY * SINPC                                            40.13
            DY2 =   DY * COSPC                                            40.13
          ELSE                                                            40.13
            DX2 =   DY * SINPC                                            40.13
            DY2 = - DY * COSPC                                            40.13
          ENDIF                                                           40.13
        ENDIF                                                             33.09
      ELSE                                                                33.09
        DX1 = XCGRID(IXCGRD(1),IYCGRD(1)) - XCGRID(IXCGRD(2),IYCGRD(2))
        DY1 = YCGRID(IXCGRD(1),IYCGRD(1)) - YCGRID(IXCGRD(2),IYCGRD(2))
        IF  ( ONED ) THEN                                                 32.02
!         *** Inclusion of virtual point ***                              32.02
          VIRT = 1.E6                                                     32.02
          IF ( SWPDIR .EQ. 1 .OR. SWPDIR .EQ. 3 ) THEN                    32.02
            DX2 = -VIRT * DY1                                             32.02
            DY2 =  VIRT * DX1                                             32.02
          ELSE IF ( SWPDIR .EQ. 2 .OR. SWPDIR .EQ. 4 ) THEN               32.02
            DX2 =  VIRT * DY1                                             32.02
            DY2 = -VIRT * DX1                                             32.02
          ENDIF                                                           32.02
        ELSE                                                              32.02
          DX2 = XCGRID(IXCGRD(1),IYCGRD(1))-XCGRID(IXCGRD(3),IYCGRD(3))
          DY2 = YCGRID(IXCGRD(1),IYCGRD(1))-YCGRID(IXCGRD(3),IYCGRD(3))
        ENDIF                                                             32.02
      ENDIF                                                               33.09
!
      DET    =  DY2*DX1 - DY1*DX2
      RDX(1) =  DY2/DET
      RDY(1) = -DX2/DET
      RDX(2) = -DY1/DET
      RDY(2) =  DX1/DET
!
!     in case of spherical coordinates determine cos of latitude
!     note: latitude is in degrees
!
      IF (KSPHER.GT.0) THEN
        DO IC = 1, ICMAX
          IF ( KCGRD(IC).EQ.1 ) CYCLE   ! if point is not valid, then cycle
          COSLAT(IC) =
     &    COS(DEGRAD*(YCGRID(IXCGRD(IC),IYCGRD(IC))+YOFFS))               33.09
        ENDDO
        DO IXY = 1, 2                                                     40.08
          RDY(IXY) = RDY(IXY) / LENDEG                                    33.09
          RDX(IXY) = RDX(IXY) / (COSLAT(1) * LENDEG)                      33.09
        ENDDO
      ENDIF
!
      IF (TESTFL .AND. ITEST .GE. 30) THEN
        WRITE(PRINTF,186)
 186    FORMAT(' ...POINTS IN STENCIL IN SUBROUTINE SWGEOM...',
     &  /,'Point: IC,  Ix,  Iy, INDEX,        Xc,        Yc')
        DO IC = 1, 3
          WRITE(PRINTF,187) IC, IXCGRD(IC)+MXF-1, IYCGRD(IC)+MYF-1,       40.30
     &                      KCGRD(IC),                                    40.30
     &    XCGRID(IXCGRD(IC),IYCGRD(IC)),YCGRID(IXCGRD(IC),IYCGRD(IC))
 187      FORMAT(3(1X,I4),3X,I5,5X,F10.2,4X,F10.2)
        ENDDO
        WRITE(PRINTF,188) DET,RDX(1),RDX(2),RDY(1),RDY(2)
 188    FORMAT('  DET,       RDX1,      RDX2,      RDY1,     RDY2',/,
     &  5(E10.4,1X))
      ENDIF

      RETURN
      END
!
!******************************************************************
!
       SUBROUTINE SWPSEL(SWPDIR    ,           IDCMIN    ,                40.00
     &                   IDCMAX    ,CAX       ,
     &                   CAY       ,ANYBIN    ,
     &                              ISCMIN    ,
     &                   ISCMAX    ,IDTOT     ,ISTOT     ,
     &                   IDDLOW    ,IDDTOP    ,ISSTOP    ,
     &                   DEP2      ,UX2       ,UY2       ,
     &                   SPCDIR    ,RDX       ,RDY       ,                40.41
     &                   KGRPNT                                           40.41 40.13 30.21
     &                                                    )
!
!******************************************************************
!
      USE SWCOMM1                                                         40.41
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
      USE M_PARALL                                                        40.31

      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     32.02: Roeland Ris & Cor van der Schelde (1D-version)
!     30.82: IJsbrand Haagsma
!     33.09, 40.00, 40.13: Nico Booij
!     40.30: Marcel Zijlema
!     40.41: Marcel Zijlema
!
!  1. Updates
!
!     20.44, Sep. 96: Subroutine completely reorganised subroutine has new name
!                     instead of COUNT
!     32.02, Feb. 98: Introduced 1D-version
!     40.00, July 98: common swcomm3 introduced, argument list changed
!     30.82, Oct. 98: Updated description of several variables
!     33.09         : spherical ccordinates introduced
!                     repeating x-axis introduced
!     40.03, Nov. 99: error messages (see formats 555 and 556) corrected
!     40.13, Mar. 01: argument KGRPNT added in view of debug output
!                     error severity changed for "blocked" points
!                     "blocked" points written to error points file
!                     comments added
!                     minimal value of ISSTOP is 4 (in view of CGSTAB solver)
!     40.13, July 01: values of DX2 and DY2 corrected in repeating coordinates
!     40.30, Mar. 03: introduction distributed-memory approach using MPI
!     40.41, Sep. 04: part concerning computation of geometric quantities
!                     moved to new routine SWGEOM
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!
!  2. PURPOSE
!
!     compute the frequency dependent counters in directional space
!     in a situation with a current and without a current.
!     The counters are only computed for the gridpoint
!     considered. This means IC = 1 (see loop with CALL for ICCODE
!     function)
!
!  3. METHOD
!
!     In absence of a current the fully 360 degrees sector is
!     subdivided in 4 sectors of 90 degrees each.
!
!     In presence of a current this is not the case anymore. The
!     counters of the directional space are frequency dependent.
!     It is first determined which bins have to taken into account
!     for a particular sweep (unconditionally stable for a specific
!     sector). To which sector a bin belongs is determined by its
!     propagation velocity Cx and Cy.
!
!     For the first sweep, all the bins with a positive propagation
!     velocity Cx and Cy have to taken into account.
!     For one particular frequency IS:
!
!
!                           #
!                        -  #  +     +
!                    -      #              +     CAX, CAY > 0
!               -           #      |
!                    IDCMAX # ..*..*..*          +
!            -              #\.....|.....*
!                          *#  \...|.......*       +
!          -                #    \.|........
!                       --*-#------O--------*--     +
!                           #      | \......
!          -               *#      |   \...*        +
!     # # # # # # # # # # # # # # # # # #\# # # # # # # # #
!                           #  *   *   *  IDCMIN
!           -               #      |               -
!                           #
!                           #                    -
!              -            #
!                                            -
!                  -                       -
!                          -     -   -
!
!
!     As can be seen from the figure, the minimum and maximum
!     counter of the directional space are determined by the
!     vectorial sum of its groupvelocity and its current
!     velocity, c_g + U. Especially the higher frequencies are
!     modified by the current. The lower frequencies (due to
!     the larger propagation velocity) are less modified by a
!     current.
!
!     In general, we can distinguish 4 cases:
!
!     SWEEP 1:
!                                              ..*..
!                                           *.........*
!                                         |. ............      |   *..*
!            |              |            *|    ..o.......*     | *......*
!            |             *|*            |...... .......      | *......*
!            |           *  |..*          |*...     ....*      |   *..*
!       -----|-----    -*---|---*-   -----|--*-------*--    ---|-------------
!            |           *  |  *          |      *             |
!       * *  |             *|*            |                    |
!     *     *|              |             |                    |
!       * *
!
!     SECTOR = 0        SECTOR = 2        SECTOR = 4       SECTOR = 1
!
!
!     The integer array SECTOR denotes which case is present for
!     a certain frequency:
!
!     0  : no bins belongs to first sweep, no sector lies within the
!          first sweep
!     2  : circle has 2 intersections with sector boundary
!     4  : circle has 4 intersections with sector boundary
!     1  : full circle lies within the first quadrant, all directions
!          have to taken into account
!
!     Furthermore it is detemined whether a certain BIN lies within
!     a specific quadrant. This is denoted by a logical array ANYBIN
!     In case of SECTOR = 4, this array is used to clear the rows
!     in the matrix IMATDA, IMATRA, IMATLA, IMATUA, which do not
!     belong to the first (or other) sweep (see subroutine SOLPRE).
!
!  4. Argument variables
!
! i   SPCDIR: (*,1); spectral directions (radians)                        30.82
!             (*,2); cosine of spectral directions                        30.82
!             (*,3); sine of spectral directions                          30.82
!             (*,4); cosine^2 of spectral directions                      30.82
!             (*,5); cosine*sine of spectral directions                   30.82
!             (*,6); sine^2 of spectral directions                        30.82
!
      REAL    SPCDIR(MDC,6)                                               30.82
!
!     INTEGERS:
!     --------------------------------------------------------------
!     IS                Counter of relative frequency band
!     ID                Counter of directional distribution
!     ICUR              Indicator for current
!     ICMAX             Indicator for nearby nodes
!     MSC               Maximum counter of relative frequency in
!                       computational model
!     MDC               Maximum counter of directional distribution in
!                       computational model
!     IDTOT             Maximum value between the lowest and highest
!                       counter in directional space
!     ISTOT             Maximum value between the lowest and highest
!                       counter in frequency space
!     FULCIR            logical: if true, computation on a full circle
!
!     REALS:
!     --------------------------------------------------------------
!     DD       input    Width of directional band
!
!     array's
!     -------
!
!     CAX     3D  propagation velocity
!     CAY     3D  propagation velocity
!     IDCMIN  1D  minimum frequency dependent counter (INTEGER)
!     IDCMAX  1D  maximum frequency dependent counter (INTEGER)
!     ISCMIN  1D  minimum counter in frequency space
!     ISCMAX  1D  maximum counter in frequency space
!     SECTOR  1D  Counter for number enclosed sectors (INTEGER)
!     ANYBIN  2D  Is a certain bin enclosed in a sweep (LOGICAL)
!     SPCDIR  1D  spectral directions                                     20.44
!     RDX,RDY 1D  array  containing spatial derivative coeff
!                 (determined in routine SWGEOM)                          40.41
!
      INTEGER, INTENT(IN)  :: KGRPNT(1:MXC,1:MYC)  ! grid addresses       40.13
!
!  6. Local variables
!
!  7. Common blocks used
!
!
!  8. Subroutines used
!
!     ---
!
!  9. Subroutines calling
!
!     SWOMPU
!
! 10. Error messages
!
!     ---
!
! 11. Remarks
!
!     ---
!
! 12. Structure
!
!     ----------------------------------------------------------
!     If current is on AND the current velocity is not equal zero then
!         compute for every frequency for every sweep the minimum
!         and maximum counters.
!         The minimum counter denotes the conversion from -- to ++
!         The maximum counter denotes the conversion from ++ to --
!
!         ++++++++++ ---------- +++++++++
!                 IDCMAX      IDCMIN
!
!         --------- ++++++++++ ----------
!                IDCMIN      IDCMAX
!
!     else if current is off or Ux=0 m/s and Uy = 0 m/s.
!         Without currents, the directional space counters
!         are constant during the computation, i.e. 4 sectors
!         of 90 degrees each
!     --------------------------------------------------------
!     End of SWPSEL
!     --------------------------------------------------------
!
! 13. Source text
!
      INTEGER   IS    ,ID    ,                     SWPDIR,                40.00
     &                 IDSUM ,IDCLOW,IDCHGH,
     &          IDTOT ,ISTOT ,
     &          IDDLOW,IDDTOP,ISSLOW,ISSTOP,
     &          IENT, IDDUM, ISCLOW, ISCHGH, IX, IY ,IC                   40.41
!
      REAL      CAXMID,CAYMID,                                            40.00
     &          GROUP, UABS, THDIR                                        40.41
!
      INTEGER   IDCMIN(MSC)     ,
     &          IDCMAX(MSC)     ,
     &          ISCMIN(MDC)     ,
     &          ISCMAX(MDC)     ,
     &          SECTOR(MSC)
!
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  ::  CAX(MDC,MSC,MICMAX)                                       40.22
      REAL  ::  CAY(MDC,MSC,MICMAX)                                       40.22
      REAL  ::  DEP2(MCGRD)         ,
     &          UX2(MCGRD)          ,
     &          UY2(MCGRD)          ,
     &          RDX(MICMAX), RDY(MICMAX)                                  40.08
!
      LOGICAL   ANYBIN(MDC,MSC)     ,
     &          LOWEST, LOWBIN, HGHBIN
!
      SAVE IENT
      DATA IENT/0/
      CALL STRACE (IENT,'SWPSEL')
!
!     *** initialize array's in theta direction ***
!
      DO 50 IS = 1, MSC
        IDCMIN(IS) = 0
        IDCMAX(IS) = 0
        SECTOR(IS) = 0
        DO 49 ID = 1, MDC
          ANYBIN(ID,IS) = .FALSE.
 49     CONTINUE
 50   CONTINUE
!
!     *** initialize arrays in frequency direction ***
!
      DO 48 ID = 1, MDC
        ISCMIN(ID) = 1
        ISCMAX(ID) = 1
 48   CONTINUE
!
!     *** set variables ***
!
      IDTOT  =     1
      ISTOT  =     1
      ISSLOW =  9999                                                      40.13
      ISSTOP = -9999                                                      40.13
!
!     --- part of computation of RDXs and RDYs moved to routine SWGEOM    40.41
!
!     *** For curvilinear version we do not distinguish if      ***
!     *** there is current or not, to know if certain bin       ***
!     *** belongs to certain sweep              VER. 30.21      ***
!
!     *** calculate minimum and maximum counters in theta space ***
!     *** if a current is present: IDCMIN and IDCMAX            ***
!
!     *** DO LOOP totally organized for curvilinear 30.21       ***

      DO 500 IS = 1, MSC
        IDCLOW  = 0
        IDCHGH  = 0
        IDSUM   = 0
        DO ID = 1, MDC
          IF (IS .EQ. 1 .OR. ICUR .GT. 0) THEN
            CAXMID = CAX(ID,IS,1)*RDX(1) + CAY(ID,IS,1)*RDY(1)
            CAYMID = CAX(ID,IS,1)*RDX(2) + CAY(ID,IS,1)*RDY(2)
            IF (CAXMID .GE. 0. .AND. CAYMID .GE. 0.) THEN
              ANYBIN(ID,IS) = .TRUE.
              IDSUM = IDSUM + 1
              ISSLOW = MIN(IS,ISSLOW)                                     40.13
              ISSTOP = MAX(IS,ISSTOP)                                     40.13
            ENDIF
            IF (TESTFL .AND. ITEST .GE. 190)                              40.00
     &         WRITE(PRINTF,333) IS,ID,CAXMID,CAYMID,ANYBIN(ID,IS)
 333        FORMAT( ' IS ID CXM CYM ANYBIN :',2(1X,I4),2(1X,E11.4),L2)
          ELSE
!           no current: if bin IS=1 is in sweep, all with same ID are     40.13
            ANYBIN(ID,IS) = ANYBIN(ID,1)
            IF (ANYBIN(ID,1)) THEN
              IDSUM = IDSUM + 1
              ISSTOP = MAX(IS,ISSTOP)                                     40.13
            ENDIF
          ENDIF
        ENDDO
!
!       determine boundaries of sector and array SECTOR
!
        DO 400 ID = 1, MDC
          LOWBIN = .FALSE.
          HGHBIN = .FALSE.
          IF (ANYBIN(ID,IS)) THEN
!           check if this active bin is a lower Theta-boundary            40.13
            IF ( ID .EQ. 1 ) THEN
              IF (FULCIR) THEN
                IF (.NOT.ANYBIN(MDC,IS)) LOWBIN = .TRUE.                  40.00
              ELSE
                LOWBIN = .TRUE.                                           40.00
              ENDIF
            ELSE
              IF (.NOT.ANYBIN(ID-1,IS)) LOWBIN = .TRUE.
            ENDIF
!           check if this active bin is a higher Theta-boundary           40.13
            IF ( ID .EQ. MDC ) THEN
              IF (FULCIR) THEN
                IF (.NOT.ANYBIN(1,IS)) HGHBIN = .TRUE.                    40.00
              ELSE
                HGHBIN = .TRUE.                                           40.00
              ENDIF
            ELSE
              IF (.NOT.ANYBIN(ID+1,IS)) HGHBIN = .TRUE.
            ENDIF
          END IF
          IF (LOWBIN) THEN
            SECTOR(IS) = SECTOR(IS) + 1
            IDCLOW = ID
          ENDIF
          IF (HGHBIN) THEN
            SECTOR(IS) = SECTOR(IS) + 1
            IDCHGH = ID
          ENDIF
 400    CONTINUE
!       check value of SECTOR
        IF (SECTOR(IS).EQ.1 .OR. SECTOR(IS).EQ.3) WRITE (PRTEST, 410)
     &          SWPDIR, IS, SECTOR(IS), IDSUM, IDCLOW, IDCHGH
 410    FORMAT (' error SWPSEL directions ', 6I6)
!        *** set the minimum and maximum counters for a sweep ***
!
        IF ( IDSUM .EQ. MDC ) THEN
          IF (FULCIR .AND. SECTOR(IS).NE.0) WRITE (PRTEST, 410)
     &          SWPDIR, IS, SECTOR(IS), IDSUM, IDCLOW, IDCHGH
          IDCMIN(IS) = 1
          IDCMAX(IS) = MDC
          SECTOR(IS) = 1
        ELSE IF ( IDSUM .EQ. 0 ) THEN
!         for this IS there are no active bins
          IF (SECTOR(IS).NE.0) WRITE (PRTEST, 410) SWPDIR, IS,
     &          SECTOR(IS), IDSUM, IDCLOW, IDCHGH
!         new values assigned because old ones cause problems in SWSNL2   40.13
          IDCMIN(IS) = 9                                                  40.13
          IDCMAX(IS) = -9                                                 40.13
          SECTOR(IS) = 0
        ELSE
          IF ( IDCLOW .GT. IDCHGH ) IDCLOW = IDCLOW - MDC
          IDCMIN(IS) = IDCLOW
          IDCMAX(IS) = IDCHGH
        END IF
!
!       *** if 4 sectors are present then set counters ***
!
        IF ( SECTOR(IS) .GT. 2 ) THEN                                     10/MAR
          IDCMIN(IS) = 1
          IDCMAX(IS) = MDC
        END IF
!
 500  CONTINUE
!
!     *** calculate minimum and maximum counters in frequency ***
!     *** space if a current is present: ISCMIN and ISCMAX    ***
!
      IDDLOW =  9999
      IDDTOP = -9999
      DO IS = 1 , MSC
        IF ( SECTOR(IS) .GT. 0 ) THEN
          IDDLOW = MIN ( IDDLOW , IDCMIN(IS) )
          IDDTOP = MAX ( IDDTOP , IDCMAX(IS) )
        END IF
      ENDDO
!
!     *** Determine counters for a certain sweep ***
!
      DO 530 IDDUM = IDDLOW, IDDTOP
        ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
        LOWEST = .TRUE.
        DO 430 IS = 1, MSC
          IF (ANYBIN(ID,IS)) THEN
            IF ( LOWEST ) THEN
              ISCLOW = IS
              LOWEST = .FALSE.
            ENDIF
            ISCHGH = IS
          END IF
 430    CONTINUE
!
!       *** set the minimum and maximum counters in arrays ***
!
        IF (.NOT.LOWEST) THEN
          ISCMIN(ID) = ISCLOW
          ISCMAX(ID) = ISCHGH
          IF (ISCMIN(ID).LT.ISSLOW) WRITE (PRINTF,*)
     &    ' error SWPSEL, ISSLOW=', ISSLOW, 'ISCMIN=', ISCMIN(ID),
     &    ' for ID=', ID
          IF (ISCMAX(ID).GT.ISSTOP) WRITE (PRINTF,*)
     &    ' error SWPSEL, ISSTOP=', ISSTOP, 'ISCMAX=', ISCMAX(ID),
     &    ' for ID=', ID
        ELSE
!         *** no frequencies fall within the sweep ***
          ISCMIN(ID) = 0
          ISCMAX(ID) = 0
        ENDIF
!
 530  CONTINUE
!
!     *** calculate the maximum number of counters in both ***
!     *** directional space and frequency space            ***
!
      IF (IDDLOW.NE.9999) THEN
        IF (IDDTOP.EQ.-9999) WRITE (PRTEST, 545) IDDLOW, IDDTOP
 545    FORMAT (' error SWPSEL min & max dir ', 5I7)
        IDTOT = ( IDDTOP - IDDLOW ) + 1
        IF (ICUR .EQ. 1) THEN
          IF (IDTOT.LT.3) THEN
            IDDTOP = IDDTOP + 1
            IF (IDTOT.EQ.1) IDDLOW = IDDLOW - 1
            IDTOT = 3
          ENDIF
        ENDIF
      ELSE
        IF (IDDTOP.NE.-9999) WRITE (PRTEST, 545) IDDLOW, IDDTOP
        IDTOT = 0
      ENDIF
!
      IF (ISSLOW.NE.9999) THEN
        IF (ITEST.GE.20) THEN                                             40.13
          IF (ISSLOW.NE.1 .OR. ISSTOP.EQ.-9999)
     &    WRITE (PRTEST, 555) IXCGRD(1)-1, IYCGRD(1)-1, ISSLOW, ISSTOP    40.13
 555      FORMAT (' error SWPSEL in:', 2I5,',  min & max freq ', 5I7)     40.13
        ENDIF                                                             40.13
        ISSLOW = 1
!       minimal value of ISSTOP is 4 (or MSC if MSC<4)                    40.13
        IF (ICUR.GT.0) ISSTOP = MAX(MIN(4,MSC),ISSTOP)                    40.13
        ISTOT = ( ISSTOP - ISSLOW ) + 1
      ELSE
        IF (ISSTOP.NE.-9999) WRITE (PRTEST, 555) IXCGRD(1)-1,
     &              IYCGRD(1)-1, ISSLOW, ISSTOP
        ISTOT = 0
        IF (IDTOT.NE.0) WRITE (PRTEST, 556) IXCGRD(1)-1,
     &              IYCGRD(1)-1, ISSLOW, ISSTOP, IDDLOW, IDDTOP           40.03
 556    FORMAT (' error SWPSEL in:', 2I5,'  min&max freq&dir ', 5I7)      40.03
      ENDIF
!
!     *** check if IDTOT is less then MDC ***
!
      IF ( IDTOT .GT. MDC ) THEN
        IDDLOW = 1
        IDDTOP = MDC
        IDTOT  = MDC
      END IF
!
!     *** check if the lowest frequency is not blocked !    ***
!     *** this can occur in real cases if the depth is very ***
!     *** small and the current velocity is large           ***
!     *** the propagation velocity Cg = sqrt (gd) < U       ***
!
      IF (ICUR .EQ. 1 .AND. FULCIR .AND.
     &    ISSLOW.NE.1 .AND. ISSLOW.NE.9999) THEN                          40.13
        CALL MSGERR (2,'The lowest freqency is blocked')                  40.13
        WRITE (PRINTF, 612) ' at point:', IXCGRD(1)+MXF-2,                40.41
     &                                    IYCGRD(1)+MYF-2,                40.41 40.13
     &      ' dep=', DEP2(KCGRD(1)),
     &      '  U=', UX2(KCGRD(1)), UY2(KCGRD(1))
 612    FORMAT (A, 2I4, A, F6.2, A, 2F6.2)                                40.13
        IF (ITEST.GE.10) THEN
          WRITE (PRINTF, 614) ' spectral limits:', ISTOT, ISSLOW,
     &    ISSTOP, IDTOT, IDDLOW, IDDTOP, ' sweep=',SWPDIR
 614      FORMAT (A, 6I8,A,I1)
          IF (ITEST.GE.60) THEN
            IF (IXCGRD(1).GT.1 .AND. IXCGRD(1).LT.MXC .AND.
     &          IYCGRD(1).GT.1 .AND. IYCGRD(1).LT.MYC) THEN
              WRITE (PRINTF, *) ' surrounding points'
              DO IY=-1,1
                WRITE (PRINTF, 621)
     &          (KGRPNT(IXCGRD(1)+IX,IYCGRD(1)+IY), IX=-1,1),
     &          (DEP2(KGRPNT(IXCGRD(1)+IX,IYCGRD(1)+IY)), IX=-1,1),
     &          (UX2(KGRPNT(IXCGRD(1)+IX,IYCGRD(1)+IY)), IX=-1,1),
     &          (UY2(KGRPNT(IXCGRD(1)+IX,IYCGRD(1)+IY)), IX=-1,1)         40.13
 621            FORMAT (1X, 3I6, 3(' | ', 3F9.2))
              ENDDO
            ENDIF
          ENDIF
        ENDIF
!       write this point to ERRPTS file (BLOCKed option)                  40.13
        IF (ERRPTS.GT.0.AND.IAMMASTER) THEN                               40.95 40.30
           WRITE(ERRPTS,7002) IXCGRD(1)+MXF-1, IYCGRD(1)+MYF-1, 3         40.30
        END IF                                                            40.13
 7002   FORMAT (I4, 1X, I4, 1X, I2)                                       40.13
        IC = 1
        GROUP = SQRT ( GRAV * DEP2(KCGRD(IC)) )
        UABS  = SQRT ( UX2(KCGRD(IC))**2 + UY2(KCGRD(IC))**2 )
        IF ( UABS .GT. GROUP ) THEN
          WRITE(PRINTF,1002) IXCGRD(IC)-1, IYCGRD(1)-1, UABS, GROUP       40.13
 1002     FORMAT(' warning, at point:',2I4,' |U|=',F8.2,' > Cg=',F8.2)    40.13
        ENDIF
      ENDIF
!
!     *** test output ***
!
      IF ( TESTFL .AND. ITEST .GE. 30 ) THEN
        IC = 1                                                            40.00
        WRITE (PRTEST,6020) KCGRD(IC),SWPDIR,ICUR
 6020   FORMAT (' subr SWPSEL: Point  SWPDIR ICUR :',3I5 )                40.00
        WRITE (PRTEST,6220) IDDLOW, IDDTOP ,ISSLOW, ISSTOP
 6220   FORMAT ('      IDDLOW IDDTOP ISSLOW ISSTOP:',4I4 )
        WRITE (PRTEST,6320) IDTOT , ISTOT
 6320   FORMAT ('      IDTOT ISTOT                :',4I4 )
        IF (ITEST.GE.120) THEN                                            40.00
          WRITE(PRTEST,*) ' Counters in directional space '
          WRITE(PRTEST,*) '       IS     IDCMIN  IDCMAX  SECTOR'          40.00
          DO IS = ISSLOW, ISSTOP
            WRITE(PRTEST,509) IS, IDCMIN(IS), IDCMAX(IS) , SECTOR(IS)
 509        FORMAT(2X,I5,3X,3I8)
          ENDDO
          WRITE(PRTEST,*) ' Counters in frequency space '
          WRITE(PRTEST,*) '       ID     ISCMIN  ISCMAX  THETA'
          DO IDDUM = IDDTOP, IDDLOW, -1
            ID = MOD ( IDDUM - 1 + MDC, MDC) + 1
            THDIR = SPCDIR(ID,1) * 180. / PI
            WRITE(PRTEST,519) ID, ISCMIN(ID), ISCMAX(ID), THDIR
 519        FORMAT(2X,I5,3X,2I8,3X,F8.2)
          ENDDO
          WRITE(PRTEST,*)
        ENDIF                                                             40.00
        IF (IDTOT.GT.0) THEN
          IF (ITEST.GE.90) THEN                                           40.00
            WRITE(PRTEST,122) IDDLOW, IDDTOP
 122        FORMAT (' Active bins in spectral space -> ID: ',
     &              I3,' to ',I3)
            DO IDDUM = IDDTOP+1, IDDLOW-1, -1
              ID = MOD ( IDDUM - 1 + MDC, MDC) + 1
              WRITE(PRTEST,124)
     &            ID, (ANYBIN(ID,IS),IS=ISSLOW, MIN(ISSTOP,25))           40.00
 124          FORMAT(I4,25L3)
            ENDDO
            WRITE(PRTEST,125)(IS, IS=ISSLOW+4, MIN(ISSTOP,25), 5 )
 125        FORMAT(6X,'1',9X,5(I3,12X))
            WRITE(PRTEST,*)
          ENDIF                                                           40.00
        ELSE
          WRITE(PRTEST,123) SWPDIR
 123      FORMAT (' No active bins in sweep', I2)
        ENDIF
        IF ( ICUR .EQ. 0 ) THEN
          WRITE (PRTEST,615) IDDLOW, IDDTOP
 615      FORMAT (' SWPSEL: IDDLOW IDDTOP  :',5(1X,I3))
        END IF
      END IF
!
!     End of the subroutine SWPSEL
!
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE SPROXY (CAX        ,
     &                   CAY        ,CGO        ,ECOS       ,
     &                   ESIN       ,UX2        ,UY2        ,
     &                   SWPDIR
     &                                                      )
!
!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
      USE M_DIFFR                                                         40.21
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!     1. UPDATE
!
!        40.13, Oct. 01: loop over IC now inside this subroutine
!        40.21, Aug. 01: adaption of velocities in case of diffraction
!        40.41, Oct. 04: common blocks replaced by modules, include files removed
!
!     2. PURPOSE
!
!        computes the propagation velocities of energy in X-, Y-
!        -space, i.e., CAX, CAY, in the presence or absence of
!        currents, for the action balance equation.
!
!        The propagation velocities are computed for the fully 360
!        degrees sector.
!
!     3. METHOD
!
!        The next equation are calculated:
!
!              @X     _
!        CAX = -- = n C cos (id) + Ux  = CGO cos(id) + Ux
!              @T
!
!              @Y     _
!        CAY = -- = n C sin(id)  + Uy  = CGO sin(id) + Uy
!              @T
!                                                         _
!     4. PARAMETERLIST
!
!        IC       Dummy variable: ICode gridpoint:
!                 IC = 1  Top or Bottom gridpoint
!                 IC = 2  Left or Right gridpoint
!                 IC = 3  Central gridpoint
!                Whether which value IC has, depends of the sweep
!                If necessary ic can be enlarged by increasing
!                the array size of ICMAX
!        IX      Counter of gridpoints in x-direction
!        IY      Counter of gridpoints in y-direction
!        IS      Counter of relative frequency band
!        ID      Counter of directional distribution
!        ICUR    Indicator for current
!        ICMAX   Maximum array size for the points of the molecule
!        MXC     Maximum counter of gridppoints in x-direction
!        MYC     Maximum counter of gridppoints in y-direction
!        MSC     Maximum counter of relative frequency
!        MDC     Maximum counter of spectral directions
!
!        REAL:
!        ----
!        COEF    auxiliary coefficient
!        VLSINH  value of the SINH for a certain value of 2KD
!
!
!        one and more dimensional arrays:
!        ---------------------------------
!
!        CAX    3D    Wave transport velocity in x-dirction, function of
!                     (ID,IS,IC)
!        CAY    3D    Wave transport velocity in y-dirction, function of
!                     (ID,IS,IC)
!        CGO    2D    group velocity
!        DEP2   2D    (Nonstationary case) depth as function of X and Y
!                     at time T+DIT
!        ECOS   1D    Represent the values of cos(d) of each spectral
!                     direction
!        ESIN   1D    Represent the values of sin(d) of each spectral
!                     direction
!        KWAVE  2D    wavenumber as function of the relative frequency S
!        UX2    2D    X-component of current velocity of X and Y at
!                     time T+1
!        UY2    2D    Y-component of current velocity of X and Y at
!                     time T+1
!
!     5. SUBROUTINES CALLING
!
!        ---
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. Common blocks used
!
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!       ******************************************************************
!       *  attention! in the action balance equation the term            *
!       *  dx                                                            *
!       *  -- = CGO + U = CX  with x, CGO, U and CX vectors              *
!       *  dt                                                            *
!       *  is in the literature the term dx/dt often indicated           *
!       *  with CX and CY in the action balance equation.                *
!       *  In this program we use:    CAX = CGO + U                      *
!       ******************************************************************
!
!   ------------------------------------------------------------
!   If depth is negative ( DEP(IX,IY) <= 0), then,
!     For every point in S and D-direction do,
!       Give propagation velocities default values :
!       CAX(ID,IS,IC)     = 0.   {propagation velocity of energy in X-dir.}
!       CAY(ID,IS,IC)     = 0.   {propagation velocity of energy in Y-dir.}
!     ---------------------------------------------------------
!   Else if current is on (ICUR > 0) then,
!     For every point in S and D-direction do,  {using the output of SWAPAR}
!       S = logaritmic distributed via LOGSIG
!       Compute propagation velocity in X-direction:
!
!               1    K(IS,IC)DEP2(IX,IY)      S cos(D)
!       CAX = ( - + ------------------------) --------- + UX2(IX,IY)
!               2   sinh 2K(IS,IC)DEP2(IX,IY) |K(IS,IC)|
!
!       ------------------------------------------------------
!       Compute propagation velocity in Y-direction:
!
!               1    K(IS,IC)DEP2(IX,IY)      S sin(D)
!       CAY = ( - + ------------------------) -------- + UY2(IX,IY)
!               2   sinh 2K(IS,IC)DEP2(IX,IY) |K(IS,IC)|
!
!       ------------------------------------------------------
!   Else if current is not on (ICUR = 0)
!     For every point in S and D-direction do
!       S = logarithmic distributed via LOGSIG
!       Compute propagation velocity in X-direction:
!
!               1    K(IS,IC)DEP2(IX,IY)        S cos(D)
!       CAX = ( - + ------------------------) ----------
!               2   sinh 2K(IS,IC)DEP2(IX,IY)  |K(IS,IC)|
!
!       ------------------------------------------------------
!       Compute propagation velocity in Y-direction:
!
!               1    K(IS,IC)DEP2(IX,IY)        S sin(D)
!       CAY = ( - + ------------------------) ----------
!               2   sinh 2K(IS,IC)DEP2(IX,IY)  |K(IS,IC)|
!
!     ----------------------------------------------------------
!   End IF
!   ------------------------------------------------------------
!   End of SPROXY
!   ------------------------------------------------------------
!
!     10. SOURCE
!
!************************************************************************
!
      INTEGER  IENT, IP, IC    ,IS    ,ID    ,SWPDIR
!
      REAL     CAX(MDC,MSC,ICMAX)          ,
     &         CAY(MDC,MSC,ICMAX)          ,
     &         CGO(MSC,ICMAX)              ,
     &         ECOS(MDC)                   ,
     &         ESIN(MDC)                   ,
     &         UX2(MCGRD)                ,
     &         UY2(MCGRD)
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'SPROXY')
!
      IF (TESTFL .AND. ITEST .GE. 5 ) WRITE (PRTEST,2)SWPDIR,KCGRD(1)
    2 FORMAT (' Start SPROXY ', 4I5)
!
      DO IC = 1, ICMAX                                                    40.13
        IF ( KCGRD(IC) .LE. 1 ) THEN                                      30.21
          DO 50 IS = 1, MSC
            DO 40 ID = 1 , MDC
              CAX(ID,IS,IC) = 0.
              CAY(ID,IS,IC) = 0.
 40         CONTINUE
 50       CONTINUE
        ELSE
!
          DO 70 IS = 1, MSC
             DO 60 ID = 1, MDC
                CAX(ID,IS,IC) = CGO(IS,IC) * ECOS(ID)
                CAY(ID,IS,IC) = CGO(IS,IC) * ESIN(ID)
 60          CONTINUE
 70       CONTINUE
!
!         --- adapt the velocities in case of diffraction
!
          IF (IDIFFR.EQ.1 .AND. PDIFFR(3).NE.0.) THEN                     40.21
             DO 90 IS = 1, MSC
                DO 80 ID = 1 ,MDC
                   CAX(ID,IS,IC) = CAX(ID,IS,IC)*DIFPARAM(KCGRD(IC))      40.21
                   CAY(ID,IS,IC) = CAY(ID,IS,IC)*DIFPARAM(KCGRD(IC))      40.21
 80             CONTINUE
 90          CONTINUE
          END IF
!
!         --- ambient currents added
!
          IF (ICUR.EQ.1)  THEN                                            40.13
             DO 110 IS = 1, MSC
                DO 100 ID = 1, MDC
                   CAX(ID,IS,IC) = CAX(ID,IS,IC) + UX2(KCGRD(IC))
                   CAY(ID,IS,IC) = CAY(ID,IS,IC) + UY2(KCGRD(IC))
100             CONTINUE
110          CONTINUE
          END IF
!
        ENDIF
!
!       *** test output ***
!
        IF ( IC .EQ. 1 .AND. TESTFL .AND. ITEST .GE. 120 ) THEN
          DO IP = 1, ICMAX
            WRITE(PRINTF,6018) IP,KCGRD(IP),
     &                         UX2(KCGRD(IP)),UY2(KCGRD(IP))
          ENDDO
 6018     FORMAT(' SPROXY: IC INDEX UX2 UY2       :', 2I5,
     &           '  UX,UY:', 2(1X,E12.4))
          IF (ITEST.GE.220) THEN                                            40.00
            DO 6002 IS = 1, MSC
              DO 6001 ID = 1, MDC
                WRITE(PRINTF,6020) IS, ID,
     &               (CAX(ID,IS,IP), CAY(ID,IS,IP), IP=1,ICMAX)           40.00
 6020           FORMAT(' IS ID <CAX CAY>:',2I4,10(1X,2E11.4))
 6001         CONTINUE
 6002       CONTINUE
          ENDIF                                                           40.00
        ENDIF
      ENDDO            ! end loop over IC
!
      RETURN
      END subroutine SPROXY
!
!****************************************************************
!
      SUBROUTINE SPROSD (SPCSIG     ,KWAVE      ,CAS        ,             40.03
     &                   CAD        ,CGO        ,                         30.80
     &                   DEP2       ,DEP1       ,ECOS       ,
     &                   ESIN       ,UX2        ,UY2        ,
     &                   COSCOS     ,SINSIN     ,SINCOS     ,             30.80
     &                   RDX        ,RDY        ,                         30.80
     &                   CAX        ,CAY        ,                         30.80
     &                   XCGRID     ,YCGRID     ,                         30.80
     &                   IDDLOW     ,IDDTOP                               40.61
     &                                                      )
!
!****************************************************************
!
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE TIMECOMM                                                        40.41
      USE OCPCOMM4                                                        40.41
      USE M_PARALL                                                        40.31
      USE M_DIFFR                                                         40.21
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!     30.72: IJsbrand Haagsma
!     30.80: Nico Booij
!     40.03: Nico Booij
!     40.02: IJsbrand Haagsma
!     40.14: Annette Kieftenburg
!     40.21: Agnieszka Herman
!     40.30: Marcel Zijlema
!     40.41: Marcel Zijlema
!     40.59: Erick Rogers
!     40.61: John Warner
!     41.06: Gerbrant van Vledder
!     41.35: Casey Dietrich
!
!  1. Updates
!
!     30.72, Feb. 98: Introduced generic names XCGRID, YCGRID and SPCSIG for SWAN
!     30.80, Nov. 98: Provision for limitation on Ctheta (refraction)
!     30.80, Aug. 99: SWCOMM3.INC included
!     30.80, Sep. 99: SWCOMM2.INC included, limitation modified
!     40.03, Dec. 99: for directions outside the current sweep the depth and
!                     current gradients are computed using the gradient at the
!                     proper side of the grid point.
!                     argument KGRPNT added.
!                     argument IC removed (is always 1)
!                     argument DT removed, TIMECOMM.INC included
!                     code completely revised
!     40.02, Jan. 00: Introduction limiter dependent on Cx, Cy, Dx and Dy
!     40.02, Sep. 00: Corrected order of handling sweeps
!     40.02, Sep. 00: Limiter on refraction only activated when IREFR=-1
!     40.14, Nov. 00: Land points excluded (bug fix)
!     40.21, Aug. 01: adaption of velocities in case of diffraction
!     40.30, Mar. 03: correcting indices of test point with offsets MXF, MYF
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     40.59, Aug. 07: replace upwind scheme with centered scheme;
!                     replace @h/@x method for computation of CAD with @C/@x method
!                     limitation procedure removed
!                     sweeping procedure removed
!     40.61, Dec. 06: correction DO loop 60 (IDCMIN, IDCMAX -> IDDLOW,IDDTOP)
!     41.06, Mar. 09: add option of limitation of velocity in theta-direction
!     41.35, Mar. 12: add option of limitation on csigma and ctheta
!
!  2. Purpose
!
!     computes the propagation velocities of energy in S- and
!     D-space, i.e., CAS, CAD, in the presence or absence of
!     currents, for the action balance equation.
!
!  3. Method
!
!     The next equation are solved numerically
!
!           @S   @S   @D   _     @D   @D          _   @U
!     CAS = -- = -- [ -- + U . ( -- + --) ] - CGO K . --
!           @T   @D   @T         @X   @Y              @s
!
!           with:   @S       KS
!                   -- =  ---------
!                   @D    sinh(2KD)
!
!           @D      Cg     @C         @C           @Ux   @Uy
!     CAD = -- = ------- [ --sin(D) - --cos(D)] + [--- - ---] *
!           @T      C      @X         @Y            @X   @Y
!
!                        @Uy               @Ux
!     * sin(D)cos(D) +   ---sin(D)sin(D) - ---cos(D)cos(D)
!                        @X                @Y
!
!     @C/@x appr by:   0.5*RDX(1) * (DEP(KCGRD(5)) - DEP(KCGRD(2)))
!                    + 0.5*RDX(2) * (DEP(KCGRD(4)) - DEP(KCGRD(3)))
!     @C/@y appr by:   0.5*RDY(1) * (DEP(KCGRD(5)) - DEP(KCGRD(2)))
!                    + 0.5*RDY(2) * (DEP(KCGRD(4)) - DEP(KCGRD(3)))
!     etc.
!
!  4. Argument variables
!
!     IDDLOW: minimum direction that is propagated within a sweep         40.61
!     IDDTOP: maximum direction that is propagated within a sweep         40.61
!
      INTEGER, INTENT(IN) :: IDDLOW, IDDTOP                               40.61
!
!     CAS   : Wave transport velocity in S-direction, function of (ID,IS,IC)
!     CAD   : Wave transport velocity in D-dirctiion, function of (ID,IS,IC)
!     CAX   : Wave transport velocity in X-direction, function of (ID,IS,IC)
!     CAY   : Wave transport velocity in Y-direction, function of (ID,IS,IC)
!     CGO   : Group velocity as function of X and Y and sigma in the
!             direction of wave propagation in absence of currents
!     DEP1  : Depth as function of X and Y at time T
!     DEP2  : (Nonstationary case) depth as function of X and Y at time T+1
!     ECOS  : Represent the values of cos(d) of each spectral direction
!     ESIN  : Represent the values of sin(d) of each spectral direction
!     KWAVE : wavenumber as function of the relative frequency sigma
!     SPCSIG: Relative frequencies in computational domain in sigma-space
!     UX2   : X-component of current velocity of X and Y at time T+1
!     UY2   : Y-component of current velocity of X and Y at time T+1
!     XCGRID: x-coordinate of comput. grid points
!     YCGRID: y-coordinate of comput. grid points
!
      REAL  :: SPCSIG(MSC)                                                30.72
      REAL  :: XCGRID(MXC,MYC), YCGRID(MXC,MYC)                           30.80
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CAS(MDC,MSC,MICMAX)                                        40.22
      REAL  :: CAD(MDC,MSC,MICMAX)                                        40.22
      REAL  :: CAX(MDC,MSC,MICMAX)                                        30.80 40.22
      REAL  :: CAY(MDC,MSC,MICMAX)                                        30.80 40.22
      REAL  :: CGO(MSC,MICMAX)                                            40.22
      REAL  :: DEP2(MCGRD)                 ,
     &         DEP1(MCGRD)                 ,
     &         ECOS(MDC)                   ,
     &         ESIN(MDC)                   ,
     &         COSCOS(MDC)                 ,
     &         SINSIN(MDC)                 ,
     &         SINCOS(MDC)
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: KWAVE(MSC,MICMAX)                                          40.22
      REAL  :: UX2(MCGRD)                  ,
     &         UY2(MCGRD)                  ,
     &         RDX(MICMAX)                 ,                              40.08
     &         RDY(MICMAX)                                                40.08
!
!     variables from common
!
!        ICUR    Indicator for current
!        NSTATC  Indicator if computation is stationary or not
!        MXC     Maximum counter of gridppoints in x-direction
!        MYC     Maximum counter of gridppoints in y-direction
!        MSC     Maximum counter of relative frequency
!        MDC     Maximum counter of spectral directions
!        DYNDEP  if True depths vary with time
!        DT      Time step
!        RDTIM   1/DT                                                     30.80
!
!     local integer variables :
!
      INTEGER  :: IENT                      ! tracing variable
      INTEGER  :: IS                        ! Counter of relative frequency band    !   30.80
      INTEGER  :: ID ,ID1   ,ID2            ! Counter of directions  !   30.80
      INTEGER  :: IDDUM                     ! aux. counter of directions !   30.80
      INTEGER  :: KCG1                      ! grid address of the active grid point  !   30.80
      INTEGER  :: KCG2  ,KCG3 , KCG4, KCG5  ! grid addresses of neighbouring grid points   !   30.80
      INTEGER  :: IX1                       ! IX1   Counter of gridpoints in x-direction  !   40.03
      INTEGER  :: IY1                       ! IY1   Counter of gridpoints in y-direction  !   40.03
!
!     local real variables :
!
      REAL  :: KD1                                    ! KD1           wavenumber * depth
      REAL  :: VLSINH                                 ! VLSINH        sinh of KD1
      REAL  :: COEF                                   ! COEF          aux. quantity
      REAL  :: CAST1,CAST2,CAST3,CAST4,CAST5          ! aux. quantities to compute Csigma !    40.03
      REAL  :: CAD_TMP                                ! aux. quantity to compute Ctheta  ! 40.59
      REAL  :: DHDX   ,DHDY                           ! depth gradient
      REAL  :: DCDX   ,DCDY                           ! celerity gradient
      REAL  :: DUXDX ,DUXDY ,DUYDX ,DUYDY             ! current velocity gradients
      REAL  :: DLOC1, DLOC2, DLOC3, DLOC4, DLOC5      ! depths at active and neighbouring grid points ! 40.59
      REAL  :: CLOC1, CLOC2, CLOC3, CLOC4, CLOC5      ! depths at active and neighbouring grid points ! 40.59
      REAL  :: CGLOC1                                 ! group velocity at active grid point ! 40.59
      REAL  :: KLOC1, KLOC2, KLOC3, KLOC4, KLOC5      ! wavenumbers at active and neighbouring grid points ! 40.59
      REAL  :: UXLOC1, UXLOC2, UXLOC3, UXLOC4, UXLOC5 ! Ux at active and neighbouring grid points ! 40.59
      REAL  :: UYLOC1, UYLOC2, UYLOC3, UYLOC4, UYLOC5 ! Uy at active and neighbouring grid points ! 40.59
!
      REAL  :: ALPHA                                  ! upper limit of CFL restriction ! 41.35
      REAL  :: FAC                                    ! a factor ! 41.06
      REAL  :: FAC2                                   ! another factor ! 41.35
      REAL  :: FRLIM                                  ! frequency range in which limit on Ctheta is applied ! 41.06
      REAL  :: PP                                     ! power of the frequency dependent limiter on refraction ! 41.06
!
!  8. Remarks
!
!  Motivation for using @C/@x instead of @h/@x :                                                                                     40.59
!  Formulae for computing CAD via @h/@x and @C/@x are identical. However, they differ in result due to numerics.                     40.59
!     Experiments suggest that @C/@x method with coarse resolution yields results that are similar to those                          40.59
!     using @C/@x or @h/@x with high resolution.                                                                                     40.59
!     By contrast, @h/@x method with coarse resolution yields considerably different result.                                         40.59
!  Further, using @C/@x allows for adding refraction by additional variables included in dispersion relation.                        40.59
!     Specifically, non-rigid seafloor (mud) can cause refraction even when water layer thickness (i.e. depths) are uniform.         40.59
!     Obviously, this type of refraction does require the mud to be non-uniform.                                                     40.59

!  Motivation for using centered scheme instead of upwind scheme :                                                                   40.59
!  Similar to above, the difference is only in numerics; experimental results suggest                                                40.59
!     better representation of unknown true solution via centered scheme.                                                            40.59
!  Further, upwind scheme can lead to non-physical asymmetry in CAD, and therefore wave action field                                 40.59
!  Further still, implementation of the upwind scheme in versions such as 40.41 and 40.51 used sweeping to                           40.59
!     keep track of results from neighboring sweeps. This involved large amounts of additional code, which is obviously undesirable. 40.59
!     The utility of this sweeping is not known to this author, since it does not seem to be strictly required by the upwind scheme. 40.59
!     As evidence, note that v30.75 used the upwind scheme, but did not have additional code for sweeping in SPROSD.                 40.59

!  Note that since we are using a centered scheme now, we stop before we get to the last grid point.                                 40.59
!  It would be possible to have separate code for falling back to the upwind scheme,                                                 40.59
!  but this may require sweeping, which would mean much additional code, see e.g. code of public release v40.51                      40.59

!  Note: RDX and RDY are unavailable for P5-P2 and P4-P3, so we use as approximation, 0.5*RDX(1), etc.                               40.59
!  Experience with implementation of more precise calculations of RDX,RDY, specifically with the SORDUP scheme,                      40.59
!      yielded imperceptible change in results. However, this could be added later if sufficiently motivated.                        40.59

!  The depth refraction limitation procedure (i.e. IREFR=-1) has been removed, because it is basically a "dirty fix" which           40.59
!      we hope/expect has been made unnecessary by the other changes here. If we are wrong about this, the "dirty fix" can be        40.59
!      restored, but this is not straightforward, since C is computed from k, which is an input argument not affected by IREFR.      40.59
!      To make this work, the depths would be limited here in SPROSD and k would then need to be calculated                          40.59
!      using the limited depths within SPROSD.                                                                                       40.59
!
!  9. STRUCTURE
!   ------------------------------------------------------------
!       determine celerity and current gradients
!   ------------------------------------------------------------
!   For each frequency do
!       determine auxiliary quantities depending on sigma
!           ----------------------------------------------------
!           using gradients ,  determine
!           Csigma (CAS) and Ctheta (CAD)
!   ------------------------------------------------------------
!   If ITFRE=0
!   Then make values of CAS=0
!   ------------------------------------------------------------
!   If IREFR=0
!   Then make values of CAD=0
!   ------------------------------------------------------------
!
!   10. SOURCE
!
!************************************************************************

      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'SPROSD')

      CAST1 = 0.
      CAST2 = 0.
      CAST3 = 0.
      CAST4 = 0.
      CAST5 = 0.

      DHDX = 0.
      DHDY = 0.

      KCG1 = KCGRD(1)
      KCG2 = KCGRD(2)
      KCG3 = KCGRD(3)
      KCG4 = KCGRD(4)
      KCG5 = KCGRD(5)
!
!     Refraction and frequency shift are not defined for points
!     neighbouring to landpoints
!
      IF ( (KCG1.EQ.1).OR.(DEP1(KCG1).LE.DEPMIN).OR.                      30.82
     &     (KCG2.EQ.1).OR.(DEP1(KCG2).LE.DEPMIN).OR.                      30.82
     &     (KCG3.EQ.1).OR.(DEP1(KCG3).LE.DEPMIN).OR.                      30.82
     &     (KCG4.EQ.1).OR.(DEP1(KCG4).LE.DEPMIN).OR.
     &     (KCG5.EQ.1).OR.(DEP1(KCG5).LE.DEPMIN) ) THEN
         DO IS = 1, MSC
            DO ID = 1, MDC
               CAD(ID,IS,1) = 0.
               CAS(ID,IS,1) = 0.
            ENDDO
         ENDDO
         GOTO 900
      ENDIF

      IX1  = IXCGRD(1)
      IY1  = IYCGRD(1)

      DLOC1 = DEP2(KCG1)
      DLOC2 = DEP2(KCG2)                                                  40.02
      DLOC3 = DEP2(KCG3)                                                  40.02
      DLOC4 = DEP2(KCG4)                                                  40.02
      DLOC5 = DEP2(KCG5)                                                  40.02

      IF ( ICUR .EQ. 1 ) THEN

         UXLOC1 = UX2(KCG1)
         UXLOC2 = UX2(KCG2)
         UXLOC3 = UX2(KCG3)
         UXLOC4 = UX2(KCG4)
         UXLOC5 = UX2(KCG5)

         UYLOC1 = UY2(KCG1)
         UYLOC2 = UY2(KCG2)
         UYLOC3 = UY2(KCG3)
         UYLOC4 = UY2(KCG4)
         UYLOC5 = UY2(KCG5)

      ENDIF
!
!     *** test output ***
!
      IF (TESTFL .AND. ITEST .GE. 100 ) THEN
        WRITE(PRINTF, 211) IX1+MXF-2, IY1+MYF-2,                          40.30
     &                     XCGRID(IX1,IY1)+XOFFS, YCGRID(IX1,IY1)+YOFFS,
     &                     DLOC1                                          40.30
 211    FORMAT(' test SPROSD, location:',2I5,2e12.4,', depth:',F9.2)
      ENDIF
!
!     *** set some terms = 0 ***
!
      DUXDX = 0.
      DUYDY = 0.
      DUYDX = 0.
      DUXDY = 0.
!
!     *** compute the derivatives of the depth and the current velocity ***
!
! old upwind scheme:   1DX USING P1-P2
!                      1DY USING P1-P3
! new centered scheme: 2DX USING P5-P2
!                      2DY USING P4-P3

!     *** @D/@X ***
!      DHDX = 1.0*RDX(1) * (DLOC1-DLOC2) + 1.0*RDX(2) * (DLOC1-DLOC3) ! upwind scheme
      DHDX = 0.5*RDX(1) * (DLOC5-DLOC2) + 0.5*RDX(2) * (DLOC4-DLOC3) ! centered scheme       40.59
!     *** @D/@Y ***
!      DHDY = 1.0*RDY(1) * (DLOC1-DLOC2) + 1.0*RDY(2) * (DLOC1-DLOC3) ! upwind scheme
      DHDY = 0.5*RDY(1) * (DLOC5-DLOC2) + 0.5*RDY(2) * (DLOC4-DLOC3) ! centered scheme       40.59

      IF ( ICUR .EQ. 1 ) THEN  !           *** current is on ***
!
!     *** @Ux/@X ***
!         DUXDX = 1.0*RDX(1) * (UXLOC1 - UXLOC2) +
!     &           1.0*RDX(2) * (UXLOC1 - UXLOC3)
         DUXDX = 0.5*RDX(1) * (UXLOC5 - UXLOC2) +
     &           0.5*RDX(2) * (UXLOC4 - UXLOC3)                           40.59
!     *** @Ux/@Y ***
!         DUXDY = 1.0*RDY(1) * (UXLOC1 - UXLOC2) +
!     &           1.0*RDY(2) * (UXLOC1 - UXLOC3)
         DUXDY = 0.5*RDY(1) * (UXLOC5 - UXLOC2) +
     &           0.5*RDY(2) * (UXLOC4 - UXLOC3)                           40.59
!     *** @Uy/@X ***
!         DUYDX = 1.0*RDX(1) * (UYLOC1 - UYLOC2) +
!     &           1.0*RDX(2) * (UYLOC1 - UYLOC3)
         DUYDX = 0.5*RDX(1) * (UYLOC5 - UYLOC2) +
     &           0.5*RDX(2) * (UYLOC4 - UYLOC3)                           40.59
!     *** @Uy/@Y ***
!         DUYDY = 1.0*RDY(1) * (UYLOC1 - UYLOC2) +
!     &           1.0*RDY(2) * (UYLOC1 - UYLOC3)
         DUYDY = 0.5*RDY(1) * (UYLOC5 - UYLOC2) +
     &           0.5*RDY(2) * (UYLOC4 - UYLOC3)                           40.59

       CAST3 = UXLOC1 * DHDX
       CAST4 = UYLOC1 * DHDY

      ELSE     !           *** current is off ***

         DUXDX = 0.
         DUXDY = 0.
         DUYDX = 0.
         DUYDY = 0.
         CAST3 = 0.
         CAST4 = 0.

      ENDIF
!
!      *** test output ***
!
      IF (TESTFL .AND. ITEST .GE. 100 ) THEN
        IF (ICUR .EQ. 1) THEN
          WRITE(PRINTF, 412) UXLOC1,UXLOC2,UXLOC3,UYLOC1,UYLOC2,UYLOC3
412       FORMAT(10X, 'UX:',3(1X,F8.3),/, 10X, 'UY:',3(1X,F8.3))
        ENDIF
        WRITE(PRINTF, 413) RDX(1),RDX(2),RDY(1),RDY(2)
413     FORMAT(10X, 'RDX etc.:',4(1X,E12.4))
        WRITE(PRINTF, 414) DHDX,  DHDY
414     FORMAT(10x, 'DHDX,DHDY:',2(1X,E12.4))
      ENDIF
!
!      *** coefficients for CAS -> function of IX and IY only ***
!
      IF ( NSTATC.EQ.0 .OR. .NOT.DYNDEP) THEN                             40.00
         !       *** stationary calculation ***
         CAST2 = 0.
      ELSE
         !       nonstationary depth, CAST2 is @D/@t
         CAST2 = ( DLOC1 - DEP1(KCG1) ) * RDTIM
      ENDIF

      DO IS = 1, MSC

        KLOC1=KWAVE(IS,1)
        KLOC2=KWAVE(IS,2)
        KLOC3=KWAVE(IS,3)
        KLOC4=KWAVE(IS,4)
        KLOC5=KWAVE(IS,5)

        CGLOC1 = CGO(IS,1)

        CLOC1=SPCSIG(IS)/KLOC1
        CLOC2=SPCSIG(IS)/KLOC2
        CLOC3=SPCSIG(IS)/KLOC3
        CLOC4=SPCSIG(IS)/KLOC4
        CLOC5=SPCSIG(IS)/KLOC5

!       upwind scheme
!        DCDX = 1.0*RDX(1) * (CLOC1-CLOC2) + 1.0*RDX(2) * (CLOC1-CLOC3)    40.59
!        DCDY = 1.0*RDY(1) * (CLOC1-CLOC2) + 1.0*RDY(2) * (CLOC1-CLOC3)    40.59
!       centered scheme
        DCDX = 0.5*RDX(1) * (CLOC5-CLOC2) + 0.5*RDX(2) * (CLOC4-CLOC3)    40.59
        DCDY = 0.5*RDY(1) * (CLOC5-CLOC2) + 0.5*RDY(2) * (CLOC4-CLOC3)    40.59

!       *** coefficients for CAS -> function of IS only ***

        KD1 = KWAVE(IS,1) * DLOC1
        IF ( KD1 .GT. 30.0 ) KD1 = 30.
        VLSINH = SINH (2.* KD1 )
        COEF   = SPCSIG(IS) / VLSINH   ! also needed for CAD, if @h/@x method used
        CAST1  = KWAVE(IS,1) * COEF
        CAST5  = CGO(IS,1) * KWAVE(IS,1)

!       loop over spectral directions

        DO IDDUM = IDDLOW-1, IDDTOP+1 !            40.61 40.03
          ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1

!          *** computation of CAS and CAD ***

          IF ( INT(PNUMS(32)).EQ.0 ) THEN
             CAD_TMP=COEF*(ESIN(ID)*DHDX-ECOS(ID)*DHDY) ! @h/@x method, currents not included , Christoffersen, Tolman, Ris, Won et al.
          ELSE IF ( INT(PNUMS(32)).EQ.1 ) THEN
             CAD_TMP=(CGLOC1/CLOC1)*(ESIN(ID)*DCDX-ECOS(ID)*DCDY) ! @C/@x method, currents not included, Young method (1999, p. 45)
!             CAD_TMP=(CGLOC1/KLOC1)*(-1.0)*(ESIN(ID)*DKDX-ECOS(ID)*DKDY)   ! @k/@x method, differs only very slightly from @C/dx
          ENDIF

!         Intuitively, one may expect that variable currents could be included via @C/@x. However, this is not the case.
!         C is determined from sigma and k (and the latter is determined from sigma).
!         Thus, if dealing with a fixed sigma value, as in SWAN,
!            having non-uniform currents does not result in non-uniform k or C...i.e., @C/@x=0 in deep water.

          IF (ICUR .EQ. 0) THEN
             CAS(ID,IS,1)=CAST1*CAST2
             CAD(ID,IS,1)=CAD_TMP

!            --- adapt the velocity in case of diffraction                40.21
             IF (IDIFFR.EQ.1) THEN                                        40.21
                CAD(ID,IS,1) = DIFPARAM(KCG1)*CAD(ID,IS,1)
     &                       - DIFPARDX(KCG1)*CGO(IS,1)*ESIN(ID)
     &                       + DIFPARDY(KCG1)*CGO(IS,1)*ECOS(ID)          40.21
             ENDIF

          ELSE
             IF (IDIFFR.EQ.0) THEN                                        40.21
                CAS(ID,IS,1) = CAST1*(CAST2+CAST3+CAST4) -
     &                         CAST5*
     &                          (COSCOS(ID)*DUXDX +
     &                           SINCOS(ID)*(DUXDY+DUYDX) +
     &                           SINSIN(ID)*DUYDY)

                CAD(ID,IS,1) = CAD_TMP +
     &                         SINCOS(ID)*(DUXDX-DUYDY) +
     &                         SINSIN(ID)*DUYDX -
     &                         COSCOS(ID)*DUXDY ! add currents, Christoffersen, Tolman, Ris, et al.
             ELSE IF (IDIFFR.EQ.1) THEN                                   40.21
                CAS(ID,IS,1) = CAST1*(CAST2+CAST3+CAST4) -
     &                         DIFPARAM(KCG1)*CAST5*
     &                        (COSCOS(ID)*DUXDX +
     &                         SINCOS(ID)*(DUXDY+DUYDX) +
     &                         SINSIN(ID)*DUYDY)                          40.21

                CAD(ID,IS,1) = DIFPARAM(KCG1)*CAD_TMP -
     &                         DIFPARDX(KCG1)*CGO(IS,1)*ESIN(ID) +
     &                         DIFPARDY(KCG1)*CGO(IS,1)*ECOS(ID) +
     &                         SINCOS(ID)*(DUXDX-DUYDY) +
     &                         SINSIN(ID)*DUYDX -
     &                         COSCOS(ID)*DUXDY                           40.21
             ENDIF                                                        40.21
          ENDIF

        ENDDO
      ENDDO
!
!     *** for most cases CAS and CAD will be activated. Therefore ***
!     *** for IREFR is set 0 (no refraction) or ITFRE = 0 (no     ***
!     *** frequency shift) we have put the IF statement outside   ***
!     *** the internal loop above                                 ***
!
      IF (ITFRE .EQ. 0) THEN
        DO IS = 1, MSC
          DO ID = 1, MDC
            CAS(ID,IS,1) = 0.0
          ENDDO
        ENDDO
      ENDIF
!
      IF (IREFR .EQ. 0) THEN
        DO IS = 1, MSC
          DO ID = 1, MDC
            CAD(ID,IS,1) = 0.0
          ENDDO
        ENDDO
      ENDIF
!
!     --- limit Ctheta in some frequency range if requested
!
      IF ( INT(PNUMS(29)).EQ.1 ) THEN
         FRLIM = PI2*PNUMS(26)
         PP    =     PNUMS(27)
         DO IS = 1, MSC
            FAC = MIN(1.,(SPCSIG(IS)/FRLIM)**PP)
            DO ID = 1, MDC
               CAD(ID,IS,1) = FAC*CAD(ID,IS,1)
            ENDDO
         ENDDO
      ENDIF
!
!     --- limit Csigma using Courant number
!
      IF ( INT(PNUMS(33)).EQ.1 ) THEN
         !
         ALPHA = PNUMS(34)
         !
         DO IS = 1, MSC
            !
            FAC2 = ALPHA * FRINTF * SPCSIG(IS)
            !
            DO IDDUM = IDDLOW-1, IDDTOP+1
               ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
               !
               FAC = FAC2 * ( ABS((RDX(1)+RDX(2))*CAX(ID,IS,1)) +
     &                        ABS((RDY(1)+RDY(2))*CAY(ID,IS,1)) )
               !
               IF ( ABS(CAS(ID,IS,1)) > FAC ) THEN
                  CAS(ID,IS,1) = CAS(ID,IS,1) * FAC / ABS(CAS(ID,IS,1))
               ENDIF
               !
            ENDDO
            !
         ENDDO
         !
      ENDIF
!
!     --- limit Ctheta using Courant number
!
      IF ( INT(PNUMS(35)) == 1 ) THEN
         !
         ALPHA = PNUMS(36)
         !
         FAC2 = ALPHA * DDIR
         !
         DO IS = 1, MSC
            !
            DO IDDUM = IDDLOW-1, IDDTOP+1
               ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
               !
               FAC = FAC2 * ( ABS((RDX(1)+RDX(2))*CAX(ID,IS,1)) +
     &                        ABS((RDY(1)+RDY(2))*CAY(ID,IS,1)) )
               !
               IF ( ABS(CAD(ID,IS,1)) > FAC ) THEN
                  CAD(ID,IS,1) = CAD(ID,IS,1) * FAC / ABS(CAD(ID,IS,1))
               ENDIF
               !
            ENDDO
            !
         ENDDO
         !
      ENDIF
!
!     *** test output ***
!
      IF (TESTFL .AND. ITEST.GE.140) THEN                                 40.00
        IF (DYNDEP .OR. ICUR.GT.0) THEN
          WRITE(PRINTF, *) ' IS ID1 ID2        values of CAS'             40.00
          DO IS = 1, MSC
             ID1 = IDDLOW-1
             ID2 = IDDTOP+1
            WRITE(PRINTF, 619) IS, ID1, ID2,                              40.00
     &            (CAS(MOD(IDDUM-1+MDC,MDC)+1, IS, 1), IDDUM=ID1,ID2)     40.00
 619        FORMAT(3I4, 2X, 600E12.4)                                     40.00
          ENDDO
        ENDIF
        WRITE(PRINTF, *) ' IS ID1 ID2        values of CAD'               40.00
        DO IS = 1, MSC
          ID1 = IDDLOW-1
          ID2 = IDDTOP+1
          WRITE(PRINTF,619) IS, ID1, ID2,                                 40.00
     &          (CAD(MOD(IDDUM-1+MDC,MDC)+1, IS, 1), IDDUM=ID1,ID2)       40.00
        ENDDO
      ENDIF                                                               40.00
!
!     end of the subroutine SPROSD
900   RETURN
      END subroutine SPROSD
!****************************************************************
!
      SUBROUTINE DSPHER (CAD, CAX, CAY, ANYBIN, YCGRID, ECOS, ESIN)       40.41 33.09 NB!
!
!****************************************************************
!
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     33.09: Nico Booij
!     40.41: Marcel Zijlema
!
!  1. Updates
!
!     33.09, Aug. 99: new subroutine
!     40.41, Aug. 04: CG replaced by CAX*COS(D)+CAY*SIN(D)
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!
!  2. Purpose
!
!     computes the propagation velocities of energy in Theta-
!     space, i.e., CAD, due to use of spherical coordinates
!
!  3. Method
!
!     References:
!     W. E. Rogers, J. M. Kaihatu, H. A. H. Petit, N. Booij and L. H. Holthuijsen,
!     "Multiple-scale Propagation in a Third-Generation Wind Wave Model"
!     in preparation
!
!             Cg Cos(theta) Tan(latitude)
!     CAD = - ---------------------------
!                    Rearth
!
!     The group velocity CG in the direction of the wave propagation
!     in case with a current is equal to:
!
!                     1      K(IS,IC)DEP(IX,IY)        S
!     CG(ID,IS,IC)= ( - + -----------------------) --------- +
!                     2  sinh 2K(IS,IC)DEP(IX,IY)  |k(IS,IC)|
!
!                     + (UX2(IX,IY)cos(D) + UY2(IX,IY)sin(D))
!
!     which is equivalent with CAX*cos(D) + CAY*sin(D)
!
!
!  4. Argument variables
!
!        one and more dimensional arrays:
!        ---------------------------------
!
!     i  ANYBIN 2D    if True the spectral component (ID,IS) is to be
!                     computed
!
      LOGICAL  ANYBIN(MDC,MSC)
!
!     o  CAD    3D    Wave transport velocity in D-direction, function of
!                     (ID,IS,IC)
!     i  CAX    3D    propagation velocity in X-direction (CGO+UX)
!     i  CAY    3D    propagation velocity in Y-direction (CGO+UY)
!     i  YCGRID 2D    Y-coordinate (latitude) for each geographic grid point
!     i  ECOS   1D    Represent the values of Cos(Theta) of each spectral
!                     direction
!     i  ESIN   1D    Represent the values of Sin(Theta) of each spectral
!                     direction
!
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CAD(MDC,MSC,MICMAX)                                        40.22
      REAL  :: CAX(MDC,MSC,MICMAX)                                        40.41
      REAL  :: CAY(MDC,MSC,MICMAX)                                        40.41
      REAL  :: YCGRID(MXC,MYC)
      REAL  :: ECOS(MDC)
      REAL  :: ESIN(MDC)
!
!
!  4. Local variables
!
!        IX, IY       grid indices
!        ID, IS       spectral indices
!
      INTEGER :: IS    ,ID     ,IX    ,IY
!
!        TANLAT       tan of latitude
!        CTTMP        temp. value used to compute contribution to Ctheta
!
      REAL     TANLAT, CTTMP
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. ERROR MESSAGES
!
!        ---
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!        ------------------------------------------------------------
!        Calculate tan of latitude (TANLAT)
!        Then For every spectral direction do
!                 calculate Cspher
!                 For every spectral frequency do
!                     add Cspher to value of CAD
!        ------------------------------------------------------------
!
!     10. SOURCE
!
!************************************************************************
!
      INTEGER, SAVE :: IENT=0
      IF (LTRACE) CALL STRACE (IENT,'DSPHER')
!
!     *** TANLAT is Tan of Latitude
!
      IX     = IXCGRD(1)
      IY     = IYCGRD(1)
      TANLAT = TAN(DEGRAD*(YCGRID(IX,IY)+YOFFS))
!
      DO ID = 1, MDC
        CTTMP = ECOS(ID) * TANLAT / REARTH
        DO IS = 1, MSC
          CAD(ID,IS,1) = CAD(ID,IS,1) -
     &           (CAX(ID,IS,1)*ECOS(ID) + CAY(ID,IS,1)*ESIN(ID)) * CTTMP  40.41
        ENDDO
      ENDDO
!
!     end of the subroutine DSPHER
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE STRSXY (         ISSTOP  ,IDCMIN  ,IDCMAX  ,CAX     ,
     &                   CAY     ,AC2     ,AC1     ,IMATRA  ,IMATDA  ,
     &                            RDX     ,RDY     ,                      33.09
     &                   OBREDF  ,TRAC0   ,TRAC1   )
!
!****************************************************************
!
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!     0. AUTHORS
!
!        30.72: IJsbrand Haagsma
!        33.08: W. Erick Rogers (a few changes related to the S&L scheme)
!        33.09: Nico Booij (changes related to spherical coordinates)
!        40.08: Erick Rogers
!        40.41: Marcel Zijlema
!        40.85: Marcel Zijlema
!
!     1. UPDATE
!
!        30.72, Oct. 97: changed floating point comparison to avoid equality
!                        comparisons
!        new subroutine replacing STRSX and STRSY
!        time derivative is included here
!        33.08, July 98: STRSXY must use the rolled back AC when S&L is used
!                        elsewhere in the domain.
!        33.09, June 99: commons swcomm2 and swcomm3 introduced, argument list
!                        modified; introduction of spherical coordinates
!        40.08, Mar. 03: Removed artifact from code
!        40.41, Oct. 04: common blocks replaced by modules, include files removed
!        40.85, Aug. 08: store xy-propagation for output purposes
!
!     2. PURPOSE
!
!        computation of space derivative of action transport
!
!     3. METHOD
!
!        Compute the derivative in x-direction:
!        The nearby points are indicated with the index IC (see
!        FUNCTION ICODE(_,_) ):
!        Central grid point     : IC = 1, grid index KCGRD(1)
!        Point in X-direction   : IC = 2, grid index KCGRD(2)
!        Point in Y-direction   : IC = 3, grid index KCGRD(3)
!
!        @[CAX AC2]
!        --------- =
!            @x
!
!      RDX(1) *
!      [CAX(ID,IS,1).AC2(ID,IS,KCGRD(1)) - CAX(ID,IS,2).AC2(ID,IS,KCGRD(2))]
!   +  RDX(2) *
!      [CAX(ID,IS,1).AC2(ID,IS,KCGRD(1)) - CAX(ID,IS,3).AC2(ID,IS,KCGRD(3))]
!
!        @[CAY AC2]
!        --------- =
!            @y
!
!      RDY(1) *
!      [CAY(ID,IS,1).AC2(ID,IS,KCGRD(1)) - CAY(ID,IS,2).AC2(ID,IS,KCGRD(2))]
!   +  RDY(2) *
!      [CAY(ID,IS,1).AC2(ID,IS,KCGRD(1)) - CAY(ID,IS,3).AC2(ID,IS,KCGRD(3))]
!
!        in diagonal matrix: 1/DT + (RDX(1)+RDX(2)) * CAX(ID,IS,1)
!                                 + (RDY(1)+RDY(2)) * CAY(ID,IS,1)
!        in r.h.s.: AC2/DT + RDX(1) * CAX(ID,IS,2).AC2(ID,IS,KCGRD(2))
!                          + RDX(2) * CAX(ID,IS,3).AC2(ID,IS,KCGRD(3))
!                          + RDY(1) * CAY(ID,IS,2).AC2(ID,IS,KCGRD(2))
!                          + RDY(2) * CAY(ID,IS,3).AC2(ID,IS,KCGRD(3))
!
!     4. PARAMETERLIST
!
!        KCGRD   int, i     Point index for grid points in comp molecule  30.40
!                           array of length ICMAX
!        MDC     int, i     Maximum counter of directional distribution
!        MSC     int, i     Maximum counter of relative frequency
!        MCGRD   int, i     Maximum counter of gridpoints in space        30.40
!        ICMAX   int, i     Maximum counter for the points of the molecule
!        ISSTOP  int, i     highest spectral frequency counter in the sweep
!        IDCMIN  int, i     minimum value of direction counter in this sweep
!        IDCMAX  int, i     maximum value of direction counter in this sweep
!        CAX     rea, i     3D array    propagation velocity in x
!        CAY     rea, i     3D array    propagation velocity in y
!        AC2     rea, i     array  spectral action density, function of
!                           x, y, theta, sigma
!        IMATDA  rea, i/o   array  Coefficients of diagonal of matrix
!        IMATRA  rea, i/o   array  Coefficients of right hand side of matrix
!        OBREDF  rea, i     action reduction factors, function of freq and
!                           direction
!        RDX,RDY 1D   i     array  containing spatial derivative coeff
!        NUMOBS  int, i     number of obstacles in comp grid
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. ERROR MESSAGES
!
!        ---
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!   ------------------------------------------------------------
!   For every spectral bin do
!       If bin is in present sweep
!       Then If LOBST
!            Then For IC = 2 to ICMAX do
!                     multiply contribution from upwave point
!                     with reduction factor
!            ---------------------------------------------------
!            Compute the derivative in x-direction
!            Compute the derivative in y-direction
!            If computation is nonstationary
!            Then compute the derivative in t-direction
!            ---------------------------------------------------
!            Store the terms in arrays IMATRA and IMATDA
!   ------------------------------------------------------------
!
      INTEGER  IS      ,ID      ,                                         33.09
     &         IDDUM   ,ISSTOP                                            33.09
!
      REAL     FXY1 ,FXY2
!
      REAL  :: AC1(MDC,MSC,MCGRD) ,AC2(MDC,MSC,MCGRD)
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CAX(MDC,MSC,MICMAX) ,CAY(MDC,MSC,MICMAX)                   40.22
      REAL  :: IMATRA(MDC,MSC)    ,IMATDA(MDC,MSC)            ,
     &         RDX(MICMAX)        ,RDY(MICMAX)                ,           40.08
     &         TRSCF(3)            ,                                      33.09
     &         OBREDF(MDC,MSC,2)                                         040697
      REAL  :: TRAC0(MDC,MSC,MTRNP)                                       40.85
      REAL  :: TRAC1(MDC,MSC,MTRNP)                                       40.85
!
      INTEGER  IDCMIN(MSC)                ,
     &         IDCMAX(MSC)                                                33.09
!
      INTEGER IENT
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'STRSXY')
!
      IF (TESTFL .AND. ITEST .GE. 120) THEN
        WRITE(PRINTF,*) ' Initial matrix coefficients at STRSXY : '
        WRITE(PRINTF,*)
     & 'IS ID IDDUM     IMATDA    IMATRA'
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE(PRINTF,2102) IS,IDDUM,ID,
     &                 IMATDA(ID,IS), IMATRA(ID,IS)
          ENDDO
        ENDDO
      END IF
!
      DO 200 IS = 1, ISSTOP
!       test output     ver 30.50
!
        IND2 = KCGRD(2)                                                   23/MAY
        IND3 = KCGRD(3)                                                   23/MAY
!
!
        DO 100 IDDUM = IDCMIN(IS), IDCMAX(IS)
          ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
!         test output     ver 30.50
!
          IF (NUMOBS .GT. 0) THEN
            TCF1 = OBREDF(ID,IS,1)                                         040697
            TCF2 = OBREDF(ID,IS,2)                                         040697
            IF (TESTFL .AND. ITEST.GE.80) THEN                            40.01
              WRITE(PRINTF,10) KCGRD(1),ID,IS,TCF1,TCF2
 10           FORMAT(' STRSXY obst ',3(1X,I5),2(1X,E10.4))
            ENDIF
          ELSE
            TCF1 = 1.
            TCF2 = 1.
          ENDIF
!
          FXY1 = 0.
          FXY2 = 0.
!
          FXY1 =   (RDX(1)+RDX(2)) * CAX(ID,IS,1)
     &           + (RDY(1)+RDY(2)) * CAY(ID,IS,1)
!
          IF (KSPHER.EQ.0) THEN                                           33.09
!
          FXY2 =  RDX(1) * CAX(ID,IS,2)* TCF1 * AC2(ID,IS,IND2)
     &          + RDX(2) * CAX(ID,IS,3)* TCF2 * AC2(ID,IS,IND3)
     &          + RDY(1) * CAY(ID,IS,2)* TCF1 * AC2(ID,IS,IND2)
     &          + RDY(2) * CAY(ID,IS,3)* TCF2 * AC2(ID,IS,IND3)
          ELSE                                                            33.09
!           spherical coordinates                                         33.09
!
            TRSCF(2) = TCF1
            TRSCF(3) = TCF2
            DO IC = 2, 3
              FXY2 = FXY2 +
     &              RDX(IC-1) * CAX(ID,IS,IC) * TRSCF(IC) *
     &              AC2(ID,IS,KCGRD(IC))
     &            + RDY(IC-1) * CAY(ID,IS,IC) * TRSCF(IC) *
     &              AC2(ID,IS,KCGRD(IC)) * COSLAT(IC) / COSLAT(1)
            ENDDO
          ENDIF
!
!         *** the term FXY2 is known, store in IMATRA ***
!         *** the term FXY1 is unknown, store in IMATDA ***
!
!         This business of doing rollback regardless of ITERMX was an artifact 40.08
!         and has been removed. Thus, the code reverts to its form in v40.01   40.08
!
          IF (NSTATC.EQ.1) THEN                                            40.00
            IF (ITERMX.EQ.1) THEN
              ACOLD = AC2(ID,IS,KCGRD(1))
            ELSE
              ACOLD = AC1(ID,IS,KCGRD(1))
            ENDIF
            IMATRA(ID,IS) = IMATRA(ID,IS) + FXY2 + ACOLD*RDTIM            33.09
            IMATDA(ID,IS) = IMATDA(ID,IS) + FXY1 + RDTIM                  33.09
            TRAC0(ID,IS,1) = TRAC0(ID,IS,1) - FXY2 - ACOLD*RDTIM          40.85
            TRAC1(ID,IS,1) = TRAC1(ID,IS,1) + FXY1 + RDTIM                40.85
          ELSE
            IMATRA(ID,IS) = IMATRA(ID,IS) + FXY2
            IMATDA(ID,IS) = IMATDA(ID,IS) + FXY1
            TRAC0(ID,IS,1) = TRAC0(ID,IS,1) - FXY2                        40.85
            TRAC1(ID,IS,1) = TRAC1(ID,IS,1) + FXY1                        40.85
          ENDIF
!         --- Using an if statement like this--in conjunction with        40.08
!             inclusion of all directions in calculation, i.e. non-use    40.08
!             of IDCMIN, IDCMAX feature throughout code--would be a       40.08
!             "brute force" method of correcting problems with sweeping   40.08
!             and curvilinear scheme. I'm leaving it as-is for now,       40.08
!             since this would slow calculations. (Erick Rogers)          40.08
!          IF((FXY1.GE.0).AND.(FXY2.GE.0))THEN
!            IMATRA(ID,IS) = IMATRA(ID,IS) + FXY2
!            IMATDA(ID,IS) = IMATDA(ID,IS) + FXY1
!          ENDIF
!
!         *** test output ***
!
          IF ( ITEST .GE. 150 .AND. TESTFL ) THEN
            IF (NSTATC.EQ.1) THEN                                          40.00
              WRITE(PRINTF,6021) ID, FXY1, FXY2, ACOLD
 6021         FORMAT (' - ID FXY1 FXY2 ACOLD:', I4, 3(1X,E12.4))
            ELSE
              WRITE(PRINTF,6022) ID, FXY1, FXY2
 6022         FORMAT (' - ID FXY1 FXY2:', I4, 2(1X,E12.4))
            ENDIF
          ENDIF
!
 100    CONTINUE
 200  CONTINUE
!
      IF (TESTFL .AND. ITEST .GE. 100) THEN
        WRITE(PRINTF,*) '  matrix coefficients at STRSXY : '
        WRITE(PRINTF,*)
     & 'IS ID IDDUM     IMATDA    IMATRA'
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE(PRINTF,2102) IS,IDDUM,ID,
     &                 IMATDA(ID,IS), IMATRA(ID,IS)
2102        FORMAT(3I3,2E12.4)
          ENDDO
        ENDDO
      END IF
!     End of subroutine STRSXY
      RETURN
      END
!****************************************************************
!
      SUBROUTINE SORDUP (         ISSTOP  ,IDCMIN  ,IDCMAX  ,CAX     ,
     &                   CAY     ,AC2     ,IMATRA  ,IMATDA  ,
     &                            RDX     ,RDY     ,TRAC0   ,TRAC1   )    40.85 33.10
!
!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
      IMPLICIT NONE                                                       33.10
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!     0. AUTHORS
!
!        33.10: Nico Booij and Erick Rogers (changes related to the SORDUP scheme)
!        33.09: Nico Booij (changes related to spherical coordinates)
!        40.08: Erick Rogers
!        40.41: Marcel Zijlema
!        40.59: W. Erick Rogers
!        40.85: Marcel Zijlema
!        40.98: Marcel Zijlema
!
!     1. UPDATE
!
!        33.10, Jan. 2000: subroutine SORDUP created. It is a modified STRSXY.
!        40.08, Mar. 2003: Improve scheme to use dx,dy calculated over two grid
!                          spaces (instead of one) where appropriate. This involves
!                          the use of RDX(3),RDX(4),RDY(3),RDY(4). This may or may not
!                          be a noticeable improvement. (I have not seen an example of a
!                          case where the original SORDUP does poorly relative to BSBT,
!                          so this is a speculative improvement).
!                          Remove option for controllable 1st order diffusion ("XYMU",
!                          "THETAK", etc.)
!        40.41, Oct. 04: common blocks replaced by modules, include files removed
!        40.59, Aug. 07: stencil modification
!        40.85, Aug. 08: store xy-propagation for output purposes
!        40.98, Feb. 09: SORDUP scheme is made consistent
!
!     2. PURPOSE
!
!        Purpose is to compute the space derivative of action transport using
!        the SORDUP scheme.
!        This is for stationary runs only (no time derivative).
!        The scheme is 2nd order accurate.                                40.08
!        The scheme reduces to the "best" approximation of                40.08
!             d/dx which can be determined using Taylor Series for the    40.08
!             stencil (ix),(ix-1),(ix-2):                                 40.08
!                         3/2*mu*phi(ix)-2*mu*phi(ix-1)+1/2*mu*phi(ix-2)  40.08
!
!     3. METHOD
!
!     References:
!     W. E. Rogers, J. M. Kaihatu, H. A. H. Petit, N. Booij and L. H. Holthuijsen,
!     "Multiple-scale Propagation in a Third-Generation Wind Wave Model"
!     in preparation
!
!        Compute the derivative in x-direction:
!        The nearby points are indicated by KCGRD
!        KCGRD(1) :   IX  ,IY
!        KCGRD(2) :   IX-1,IY
!        KCGRD(3) :   IX  ,IY-1
!        KCGRD(6) :   IX-2,IY                                             40.59
!        KCGRD(7) :   IX  ,IY-2                                           40.59
!
!        The scheme is:
!
!        @[CAX AC2]
!        --------- =
!            @x
!
!        [1.5*CAX(ID,IS,1)*AC2(ID,IS,KCGRD(1))-2.0*CAX(ID,IS,2)*AC2(ID,IS,KCGRD(2))
!        +0.5*CAX(ID,IS,6)*AC2(ID,IS,KCGRD(6))]/DX
!
!        @[CAY AC2]
!        --------- =
!            @y
!
!        [1.5*CAY(ID,IS,1)*AC2(ID,IS,KCGRD(1))-2.0*CAY(ID,IS,3)*AC2(ID,IS,KCGRD(3))
!        +0.5*CAY(ID,IS,7)*AC2(ID,IS,KCGRD(7))]/DY
!
!        ADD TO DIAGONAL:
!        +1.5*CAX(ID,IS,1)/DX+1.5*CAY(ID,IS,1)/DY
!        ADD TO RHS:
!        +[2.0*CAX(ID,IS,2)*AC2(ID,IS,KCGRD(2)-0.5*CAX(ID,IS,6)*AC2(ID,IS,KCGRD(6)]/DX
!        +[2.0*CAY(ID,IS,3)*AC2(ID,IS,KCGRD(3)-0.5*CAY(ID,IS,7)*AC2(ID,IS,KCGRD(7)]/DY
!
!     4. PARAMETERLIST
!
!        KCGRD   int, i     Point index for grid points in comp molecule  30.40
!                           array of length ICMAX
!        MDC     int, i     Maximum counter of directional distribution
!        MSC     int, i     Maximum counter of relative frequency
!        MCGRD   int, i     Maximum counter of gridpoints in space        30.40
!        ICMAX   int, i     Maximum counter for the points of the molecule
!        ISSTOP  int, i     highest spectral frequency counter in the sweep
!        IDCMIN  int, i     minimum value of direction counter in this sweep
!        IDCMAX  int, i     maximum value of direction counter in this sweep
!        CAX     rea, i     3D array    propagation velocity in x
!        CAY     rea, i     3D array    propagation velocity in y
!        AC2     rea, i     array  spectral action density, function of
!                           x, y, theta, sigma
!        IMATDA  rea, i/o   array  Coefficients of diagonal of matrix
!        IMATRA  rea, i/o   array  Coefficients of right hand side of matrix
!        RDX,RDY 1D   i     array  containing spatial derivative coeff
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. ERROR MESSAGES
!
!        ---
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!   ------------------------------------------------------------
!   For every spectral bin do
!       If bin is in present sweep
!            ---------------------------------------------------
!            Compute the derivative in x-direction
!            Compute the derivative in y-direction
!            If computation is nonstationary
!            Then compute the derivative in t-direction
!            ---------------------------------------------------
!            Store the terms in arrays IMATRA and IMATDA
!   ------------------------------------------------------------
!
      INTEGER  IS,ID,IDDUM,ISSTOP                                         33.10
     &         ,IND2,IND3,IND6,IND7                                       40.59 33.10
!
      REAL  :: FXY1 ,FXY2
!
      REAL  :: AC2(MDC,MSC,MCGRD)                                         33.10
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CAX(MDC,MSC,MICMAX) ,CAY(MDC,MSC,MICMAX)                   40.22
      REAL  :: IMATRA(MDC,MSC)    ,IMATDA(MDC,MSC)            ,
     &         RDX(MICMAX)        ,RDY(MICMAX)                ,           40.08
     &         XMU(7)             ,YMU(7)                                 40.59 40.08 33.10
      REAL  :: TRAC0(MDC,MSC,MTRNP)                                       40.85
      REAL  :: TRAC1(MDC,MSC,MTRNP)                                       40.85

      INTEGER  IDCMIN(MSC), IDCMAX(MSC), IENT, IXY                        33.10
      LOGICAL  XNUM                                                       33.10
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'SORDUP')
!
      IF(NSTATC.EQ.1)THEN                                                 33.10
         CALL MSGERR (3, 'SORDUP scheme is for stationary mode only.')    33.10
      END IF                                                              33.10
      IF (TESTFL .AND. ITEST .GE. 120) THEN
        WRITE(PRINTF,*) ' Initial matrix coefficients at SORDUP : '
        WRITE(PRINTF,*)
     & 'IS ID IDDUM     IMATDA    IMATRA'
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE(PRINTF,2102) IS,IDDUM,ID,
     &                 IMATDA(ID,IS), IMATRA(ID,IS)
          ENDDO
        ENDDO
      END IF

      DO 200 IS = 1, ISSTOP
        IND2 = KCGRD(2)
        IND3 = KCGRD(3)
        IND6 = KCGRD(6)                                                   40.59 33.10
        IND7 = KCGRD(7)                                                   40.59 33.10
        DO 100 IDDUM = IDCMIN(IS), IDCMAX(IS)
          ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
!         find Courant number values: XMU, YMU                            40.08
!         depending on relative size of XMU and YMU, XNUM is true or      40.08
!         false because of RDX and RDY, XMU and YMU are always positive   40.08
          DO IXY=1,3                                                      40.59 40.08
             XMU(IXY) = RDX(1)*CAX(ID,IS,IXY) + RDY(1)*CAY(ID,IS,IXY)     40.08
             YMU(IXY) = RDX(2)*CAX(ID,IS,IXY) + RDY(2)*CAY(ID,IS,IXY)     40.08
          END DO                                                          40.08
          DO IXY=6,7                                                      40.59
             XMU(IXY) = RDX(1)*CAX(ID,IS,IXY) + RDY(1)*CAY(ID,IS,IXY)     40.59
             YMU(IXY) = RDX(2)*CAX(ID,IS,IXY) + RDY(2)*CAY(ID,IS,IXY)     40.59
          END DO                                                          40.59
          IF(YMU(1).GT.XMU(1))THEN                                        33.10
!            propagation mainly from grid point 3
             XNUM=.TRUE.                                                  33.10
          ELSE                                                            33.10
!            propagation mainly from grid point 2
             XNUM=.FALSE.                                                 33.10
          END IF                                                          33.10

!         now calculate diagonal and rhs                                  33.10

          IF(XNUM)THEN                                                    33.10

!           diagonal  FXY1
            FXY1 = 1.5*XMU(1) + 1.5*YMU(1)                                40.98 40.08

            IF (KSPHER.EQ.0) THEN                                         33.08
!             Cartesian coordinates

!             the known, rhs part FXY2                                    33.08
              FXY2 = AC2(ID,IS,IND2) * 2.0*XMU(2)                         40.08 33.10
     &              -AC2(ID,IS,IND6) * 0.5*XMU(6)                         40.59 40.08 33.10
     &              +AC2(ID,IS,IND3) * 2.0*YMU(3)                         40.08 33.10
     &              -AC2(ID,IS,IND7) * 0.5*YMU(7)                         40.59 40.08 33.10

            ELSE                                                          33.10
!             Spherical coordinates
!
!             the known, rhs part FXY2                                    33.08

              FXY2 =
     &        AC2(ID,IS,IND2) * CAX(ID,IS,2) * RDX(1) * 2.0               40.08 33.10
     &       -AC2(ID,IS,IND6) * CAX(ID,IS,6) * RDX(1) * 0.5               40.98 40.59 40.08 33.10
     &       +AC2(ID,IS,IND3) * CAX(ID,IS,3) * RDX(2) * 2.0               40.08 33.10
     &       -AC2(ID,IS,IND7) * CAX(ID,IS,7) * RDX(2) * 0.5               40.98 40.59 40.08 33.10
     &      +(AC2(ID,IS,IND2) * CAY(ID,IS,2) * RDY(1) * COSLAT(2) * 2.0   40.08 33.10
     &       -AC2(ID,IS,IND6) * CAY(ID,IS,6) * RDY(1) * COSLAT(6) * 0.5   40.98 40.59 40.08 33.10
     &       +AC2(ID,IS,IND3) * CAY(ID,IS,3) * RDY(2) * COSLAT(3) * 2.0   40.08 33.10
     &       -AC2(ID,IS,IND7) * CAY(ID,IS,7) * RDY(2) * COSLAT(7) * 0.5   40.98 40.59 40.08 33.10
     &        ) / COSLAT(1) !33.10
            ENDIF

          ELSE      ! switch 2<==>3, 6<==>7 and YMU<==>XMU                40.59 33.10

! The diag part FXY1
            FXY1 = 1.5*YMU(1)+ 1.5*XMU(1)                                 40.98 40.08 33.10

            IF (KSPHER.EQ.0) THEN                                         33.08
!             Cartesian coordinates

!             the known, rhs part  FXY2                                   33.08
              FXY2 = AC2(ID,IS,IND3) * 2.0*YMU(3)                         40.08 33.10
     &              -AC2(ID,IS,IND7) * 0.5*YMU(7)                         40.59 40.08 33.10
     &              +AC2(ID,IS,IND2) * 2.0*XMU(2)                         40.08 33.10
     &              -AC2(ID,IS,IND6) * 0.5*XMU(6)                         40.59 40.08 33.10

            ELSE
!             Spherical coordinates

!             the known, rhs part  FXY2                                   33.08
              FXY2 =
     &        AC2(ID,IS,IND2) * CAX(ID,IS,2) * RDX(1) * 2.0               40.08 33.10
     &       -AC2(ID,IS,IND6) * CAX(ID,IS,6) * RDX(1) * 0.5               40.98 40.59 40.08 33.10
     &       +AC2(ID,IS,IND3) * CAX(ID,IS,3) * RDX(2) * 2.0               40.08 33.10
     &       -AC2(ID,IS,IND7) * CAX(ID,IS,7) * RDX(2) * 0.5               40.98 40.59 40.08 33.10
     &      +(AC2(ID,IS,IND2) * CAY(ID,IS,2) * RDY(1) * COSLAT(2) * 2.0   40.08 33.10
     &       -AC2(ID,IS,IND6) * CAY(ID,IS,6) * RDY(1) * COSLAT(6) * 0.5   40.98 40.59 40.08 33.10
     &       +AC2(ID,IS,IND3) * CAY(ID,IS,3) * RDY(2) * COSLAT(3) * 2.0   40.08 33.10
     &       -AC2(ID,IS,IND7) * CAY(ID,IS,7) * RDY(2) * COSLAT(7) * 0.5   40.98 40.59 40.08 33.10
     &        )/ COSLAT(1)
            ENDIF
          END IF

          IF (TESTFL .AND. ITEST.GE.120) WRITE (PRTEST, 28) ID, IS,
     &    CAX(ID,IS,2), CAY(ID,IS,2), AC2(ID,IS,IND2),
     &    CAX(ID,IS,3), CAY(ID,IS,3), AC2(ID,IS,IND3)
 28       FORMAT (2I3, 6(1X,E12.4))
!
!         *** the term FXY2 is known, store in IMATRA ***
!         *** the term FXY1 is unknown, store in IMATDA ***
!
          IMATRA(ID,IS) = IMATRA(ID,IS) + FXY2
          IMATDA(ID,IS) = IMATDA(ID,IS) + FXY1
          TRAC0(ID,IS,1) = TRAC0(ID,IS,1) - FXY2                          40.85
          TRAC1(ID,IS,1) = TRAC1(ID,IS,1) + FXY1                          40.85
!
!         *** test output ***
          IF ( ITEST .GE. 150 .AND. TESTFL ) THEN
              WRITE(PRINTF,6022) ID, FXY1, FXY2
 6022         FORMAT (' - ID FXY1 FXY2:', I4, 2(1X,E12.4))
          ENDIF
!
 100    CONTINUE
 200  CONTINUE
!
      IF (TESTFL .AND. ITEST .GE. 100) THEN
        WRITE(PRINTF,*) '  matrix coefficients at SORDUP : '
        WRITE(PRINTF,*)
     & 'IS ID IDDUM     IMATDA    IMATRA'
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE(PRINTF,2102) IS,IDDUM,ID,
     &                 IMATDA(ID,IS), IMATRA(ID,IS)
 2102       FORMAT(3I3,2E12.4)
          ENDDO
        ENDDO
      END IF
!     End of subroutine SORDUP
      RETURN
      END
!****************************************************************
!
      SUBROUTINE SANDL ( ISSTOP  ,IDCMIN  ,IDCMAX  ,CGO     ,CAX     ,    33.08
     &                   CAY     ,AC2     ,AC1     ,IMATRA  ,IMATDA  ,
     &                   RDX     ,RDY     ,CAX1    ,CAY1    ,SPCDIR  ,    33.08
     &                   TRAC0   ,TRAC1   )                               40.85
!
!****************************************************************
!
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
      USE TIMECOMM                                                        40.41
!
      IMPLICIT NONE                                                       33.08
!
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!     0. AUTHORS
!
!        33.08: W. Erick Rogers
!        33.09: Nico Booij
!        40.02: IJsbrand Haagsma
!        40.08: W. Erick Rogers
!        40.41: Marcel Zijlema
!        40.85: Marcel Zijlema
!
!     1. UPDATE
!
!        33.08, July 98: SANDL: New subroutine using a Stelling and Leenderste
!                        SANDL: scheme (Qo=0,Q1=1/6) is created.
!        33.09, Aug. 99: extension with spherical coordinates
!        40.02, Aug. 00: Avoid more than 19 continuation lines
!        40.08, Feb. 03: Check for exceedence of soft CFL criterion
!        40.41, Oct. 04: common blocks replaced by modules, include files removed
!        40.85, Aug. 08: store xy-propagation for output purposes
!
!     2. PURPOSE
!
!        computation of space derivative of action transport
!
!     3. METHOD
!
!        References:
!        W.E. Rogers,  J.M. Kaihatu, N. Booij and L.H. Holthuijsen,
!        "Improving the numerics of a third-generation wave action
!        model", Naval Research Laboratory, NRL/FR/7320-99-9695, 79p.
!
!        computational stencil:                                           40.03
!
!                              4
!                             X
!                             |
!               8    6    2   |1    5
!              X----X----X----X----X
!                        |    |
!                        |    |3
!                        X----X
!                      10     |
!                             |7
!                             X
!                             |
!                             |9
!                             X
!
!        Compute the derivative in x-direction:
!        The nearby points are indicated with the index IC (see
!        above scheme):
!        Central grid point     : IC = 1, grid index KCGRD(1)
!        Point in X-direction   : IC = 2, grid index KCGRD(2)
!        Point in Y-direction   : IC = 3, grid index KCGRD(3)
!
!        @[CAX AC2]
!        --------- =
!            @x

!       (1/4DX)*(CAX1(KCGRD(5))*AC1(KCGRD(5))-CAX1(KCGRD(2))*AC1(KCGRD(2)))          33.08
!       +(1/12DX)*( 10*CAX(KCGRD(1))*AC2(KCGRD(1))-15*CAX(KCGRD(2))*AC2(KCGRD(2))    33.08
!       +6*CAX(KCGRD(6))*AC2(KCGRD(6))-1*CAX(KCGRD(8))*AC2(KCGRD(8)) )               33.08


!        @[CAY AC2]
!        --------- =
!            @y

!       (1/4DY)*(CAY1(KCGRD(4))*AC1(KCGRD(4))-CAY1(KCGRD(3))*AC1(KCGRD(3)))          33.08
!       +(1/12DY)*( 10*CAY(KCGRD(1))*AC2(KCGRD(1))-15*CAY(KCGRD(3))*AC2(KCGRD(3))    33.08
!       +6*CAY(KCGRD(7))*AC2(KCGRD(7))-1*CAY(KCGRD(9))*AC2(KCGRD(9)) )               33.08

!        in diagonal matrix: 1/DT + (5./6.)*(RDX(1)+RDX(2)) * CAX(ID,IS,1)           33.08
!                                 + (5./6.)*(RDY(1)+RDY(2)) * CAY(ID,IS,1)           33.08

!        in r.h.s.: AC1/DT + RDX(1)*CAX(ID,IS,2)*AC2(ID,IS,KCGRD(2))                 33.08
!                  +(5./4.) *RDY(2)*CAY(ID,IS,3)*AC2(ID,IS,KCGRD(3))                 33.08
!                  -(1./2.) *RDX(1)*CAX(ID,IS,6)*AC2(ID,IS,KCGRD(6))                 33.08
!                  -(1./2.) *RDY(2)*CAY(ID,IS,7)*AC2(ID,IS,KCGRD(7))                 33.08
!                  +(1./12.)*RDX(1)*CAX(ID,IS,8)*AC2(ID,IS,KCGRD(8))                 33.08
!                  +(1./12.)*RDY(2)*CAY(ID,IS,9)*AC2(ID,IS,KCGRD(9))                 33.08
!                  +(0.25*RDX(1))*(CAX1(ID,IS,2)*AC1(ID,IS,KCGRD(2))                 33.08
!                  -               CAX1(ID,IS,5)*AC1(ID,IS,KCGRD(5)))                33.08
!                  +(0.25*RDY(2))*(CAY1(ID,IS,3)*AC1(ID,IS,KCGRD(3))                 33.08
!                  -               CAY1(ID,IS,4)*AC1(ID,IS,KCGRD(4)))                33.08
!
!        To produce anisotrophic diffusion, we add to the r.h.s.:
!
!                  +RDX**2                                                           33.08
!                    *(+DXX(1)*(AC1(ID,IS,IND5)-AC1(ID,IS,IND1))                     33.08
!                      -DXX(2)*(AC1(ID,IS,IND1)-AC1(ID,IS,IND2)))                    33.08
!                  +RDY**2                                                           33.08
!                    *(+DYY(1)*(AC1(ID,IS,IND4)-AC1(ID,IS,IND1))                     33.08
!                      -DYY(3)*(AC1(ID,IS,IND1)-AC1(ID,IS,IND3)))                    33.08
!                  +(2.*DXY(1)*RDX*RDY)                                              33.08
!                           *(+AC1(ID,IS,IND1)-AC1(ID,IS,IND2)                       33.08
!                             -AC1(ID,IS,IND3)+AC1(ID,IS,IND10))                     33.08
!
!                  Where DXX, DYY, and DXY are diffusion coefficients.               33.08
!
!
!     4. PARAMETERLIST
!
!        ISSTOP  int, i     highest spectral frequency counter in the sweep
!        IDCMIN  int, i     minimum value of direction counter in this sweep
!        IDCMAX  int, i     maximum value of direction counter in this sweep
!        CGO     rea, i     2D array    group velocity                    33.08
!        CAX     rea, i     3D array    propagation velocity in x  new time level
!        CAY     rea, i     3D array    propagation velocity in y
!        CAX1    rea, i     3D array    propagation velocity in x  old time level
!        CAY1    rea, i     3D array    propagation velocity in y
!        AC2     rea, i     array  spectral action density, function of
!                           x, y, theta, sigma
!        IMATDA  rea, i/o   array  Coefficients of diagonal of matrix
!        IMATRA  rea, i/o   array  Coefficients of right hand side of matrix
!        RDX,RDY 1D   i     array  containing spatial derivative coeff
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. Local variables
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. ERROR MESSAGES
!
!        ---
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!   ------------------------------------------------------------
!   For every spectral bin do
!       If bin is in present sweep
!       Then If LOBST
!            Then For IC = 2 to ICMAX do
!                     multiply contribution from upwave point
!                     with reduction factor
!            ---------------------------------------------------
!            Compute the derivative in x-direction
!            Compute the derivative in y-direction
!            If computation is nonstationary
!            Then compute the derivative in t-direction
!            ---------------------------------------------------
!            Store the terms in arrays IMATRA and IMATDA
!   ------------------------------------------------------------
!
      INTEGER  IS      ,ID      ,IDDUM   ,ISSTOP  ,IC    ,
     &         IND1,IND2,IND3,IND4,IND5,IND6,IND7,IND8,IND9,IND10         33.08
!
      REAL     FXY1 ,FXY2, ACOLD,                                         33.08
     &         DSS, DNN, D11AC, D12AC, D22AC                              33.08
!
      REAL  :: TRAC0(MDC,MSC,MTRNP)                                       40.85
      REAL  :: TRAC1(MDC,MSC,MTRNP)                                       40.85
      REAL  :: AC1(MDC,MSC,MCGRD) ,AC2(MDC,MSC,MCGRD)
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CGO(MSC,MICMAX)                                            33.08 40.22
      REAL  :: CAX(MDC,MSC,MICMAX) ,CAY(MDC,MSC,MICMAX)                   40.22
      REAL  :: IMATRA(MDC,MSC)    ,IMATDA(MDC,MSC)
      REAL  :: RDX(MICMAX)        ,RDY(MICMAX)                            40.08
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CAX1(MDC,MSC,MICMAX),CAY1(MDC,MSC,MICMAX)                  33.08 40.22
      REAL  :: DCG, SPCDIR(MDC,6), DXX, DYY, DXY                          33.08
      REAL  :: MYU,DX1DUM,DY1DUM,DX2DUM,DY2DUM,DXMYU,DYMYU                40.08
!
      INTEGER :: IDCMIN(MSC), IDCMAX(MSC)
!
      INTEGER, SAVE :: IENT=0
      IF (LTRACE) CALL STRACE (IENT,'SANDL')
!
      IF (TESTFL .AND. ITEST .GE. 120) THEN
        WRITE(PRINTF,*) ' Initial matrix coefficients at SANDL : '
        WRITE(PRINTF,*)
     & 'IS ID IDDUM     IMATDA    IMATRA'
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE(PRINTF,2102) IS,IDDUM,ID,
     &                 IMATDA(ID,IS), IMATRA(ID,IS)
          ENDDO
        ENDDO
      END IF

      IND1 = KCGRD(1)                                                     33.08
      IND2 = KCGRD(2)
      IND3 = KCGRD(3)
      IND4 = KCGRD(4)                                                     33.08
      IND5 = KCGRD(5)                                                     33.08
      IND6 = KCGRD(6)                                                     33.08
      IND7 = KCGRD(7)                                                     33.08
      IND8 = KCGRD(8)                                                     33.08
      IND9 = KCGRD(9)                                                     33.08
      IND10 = KCGRD(10)                                                   33.08

      IF (TESTFL .AND. KSPHER.GT.0 .AND. ITEST.GE.60) THEN
         WRITE (PRTEST, 92) (COSLAT(IC), IC=1, 10)
  92     FORMAT (' Cos(Lat) ',10(1X,F7.4))
      ENDIF
      IF (WAVAGE.GT.0. .AND. ITEST.GE.120 .AND. TESTFL) THEN
        WRITE (PRTEST, *) '  ID  IS  DSS    DNN   ',
     &  '  DXX   DXY   DYY    D11AC   D12AC   D22AC'
      ENDIF
!
!     --- I have tested this code with Cartesian, curvilinear, and        40.08
!         spherical coords (Erick Rogers).                                40.08
!         Note that this might be improved by only performing the         40.08
!         check at the first time step (assuming that cgo does not        40.08
!         change greatly from one time step to the next)                  40.08

      IF(RDX(1).EQ.0.0)THEN                                               40.08
         DX1DUM=0.0                                                       40.08
      ELSE                                                                40.08
         DX1DUM=1.0/RDX(1)                                                40.08
      END IF                                                              40.08

      IF(RDY(1).EQ.0.0)THEN                                               40.08
         DY1DUM=0.0                                                       40.08
      ELSE                                                                40.08
         DY1DUM=1.0/RDY(1)                                                40.08
      END IF                                                              40.08

      IF(RDX(2).EQ.0.0)THEN                                               40.08
         DX2DUM=0.0                                                       40.08
      ELSE                                                                40.08
         DX2DUM=1.0/RDX(2)                                                40.08
      END IF                                                              40.08

      IF(RDY(2).EQ.0.0)THEN                                               40.08
         DY2DUM=0.0                                                       40.08
      ELSE                                                                40.08
         DY2DUM=1.0/RDY(2)                                                40.08
      END IF                                                              40.08

!     --- Even if KSPHER=1, dx and dy are already in meters               40.08
      DXMYU=SQRT(DY1DUM**2+DX1DUM**2)                                     40.08
      DYMYU=SQRT(DY2DUM**2+DX2DUM**2)                                     40.08
      MYU=ABS(DT*CGO(1,1)/MIN(DXMYU,DYMYU))                               40.08
!     --- Since there is no hard stability limit, we use a nonexact       40.08
!         definition of CFL. I only check IS=1, since that is the         40.08
!         fastest wave.                                                   40.08
      IF(MYU.GT.10.0)THEN                                                 40.08
         CALL MSGERR(2,'It is inadvisable to use the higher order '//     40.08
     &        'scheme for nonstationary computation with '    //          40.08
     &        'CFL greater than 10. Consider using PROP BSBT.'//          40.08
     &        ' If you are having this problem because you '  //          40.08
     &        'are trying to run a high resolution model '    //          40.08
     &        'with a large (e.g. 1 hour) time step and '     //          40.08
     &        'COMP NONSTAT: Note that for smaller domains, ' //          40.08
     &        'you can avoid this problem by using MODE '     //          40.08
     &        'NONSTAT with multiple COMP STAT lines. (COMP ' //          40.08
     &        'STAT is often ok when domain is less than '    //          40.08
     &        '100km or 1 deg on a side, as a rule of thumb)')            40.08
!        --- Note that code will stop even without this line              40.08
!            (at beginning of next time step).                            40.08
!         IF(MAXERR.LT.2) STOP                                            40.08
      END IF                                                              40.08
!
      DO 200 IS = 1, ISSTOP

        DO 100 IDDUM = IDCMIN(IS), IDCMAX(IS)
          ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1

          IF (WAVAGE.GT.0.) THEN                                          33.08
!           calculate DSS,DXX,DXY for the central grid point (IC=1)       33.08
!           we need DCG first. we calculate DCG (delta of Cg)             33.08
            IC = 1                                                        33.08
            IF (IS.EQ.1) THEN                                             33.08
              DCG = ABS(CGO(IS+1,IC)-CGO(IS,IC))                          33.08

            ELSE IF (IS.EQ.ISSTOP) THEN                                   33.08
              DCG = ABS(CGO(IS,IC)-CGO(IS-1,IC))                          33.08

            ELSE                                                          33.08
              DCG = 0.5 * ABS(CGO(IS+1,IC)-CGO(IS-1,IC))                  33.08
            END IF                                                        33.08
!           we obtain DSS etc. by using the wave age                      33.08
            DSS = DCG**2*WAVAGE/12.                                       33.08
            DNN = (CGO(IS,IC)*DDIR)**2 * WAVAGE/12.                       33.08
!           we obtain DXX etc. by multiplication with Cos(theta)^2 etc.   33.08
            DXX = DSS*SPCDIR(ID,4) + DNN*SPCDIR(ID,6)                     33.08
            DYY = DSS*SPCDIR(ID,6) + DNN*SPCDIR(ID,4)                     33.08
            DXY = (DSS-DNN)*SPCDIR(ID,5)                                  33.08
          END IF                                                          33.08

!         the unknown, diagonal part:                                     33.08

          FXY1 = 0.83333*(RDX(1)+RDX(2)) * CAX(ID,IS,1)                   33.08
     &         + 0.83333*(RDY(1)+RDY(2)) * CAY(ID,IS,1)                   33.08
          IF (KSPHER.EQ.0) THEN                                           33.08
!           Cartesian coordinates

!           the known, rhs part                                           33.08

!
!         To avoid violation of the ANSI standard this statement is split 40.02
!
            FXY2 =                                                        40.02
     &        +1.25   * RDX(1) * CAX(ID,IS,2) * AC2(ID,IS,IND2)           33.08
     &        +1.25   * RDY(1) * CAY(ID,IS,2) * AC2(ID,IS,IND2)           33.08
     &        +1.25   * RDX(2) * CAX(ID,IS,3) * AC2(ID,IS,IND3)           33.08
     &        +1.25   * RDY(2) * CAY(ID,IS,3) * AC2(ID,IS,IND3)           33.08
     &        -0.5    * RDX(1) * CAX(ID,IS,6) * AC2(ID,IS,IND6)           33.08
     &        -0.5    * RDY(1) * CAY(ID,IS,6) * AC2(ID,IS,IND6)           33.08
     &        -0.5    * RDX(2) * CAX(ID,IS,7) * AC2(ID,IS,IND7)           33.08
     &        -0.5    * RDY(2) * CAY(ID,IS,7) * AC2(ID,IS,IND7)           33.08
     &        +0.08333* RDX(1) * CAX(ID,IS,8) * AC2(ID,IS,IND8)           33.08
     &        +0.08333* RDY(1) * CAY(ID,IS,8) * AC2(ID,IS,IND8)           33.08
     &        +0.08333* RDX(2) * CAX(ID,IS,9) * AC2(ID,IS,IND9)           33.08
     &        +0.08333* RDY(2) * CAY(ID,IS,9) * AC2(ID,IS,IND9)           33.08
            FXY2 = FXY2 + (                                               40.02
     &        +(0.25*RDX(1)) * (CAX1(ID,IS,2) * AC1(ID,IS,IND2)           33.08
     &        -                 CAX1(ID,IS,5) * AC1(ID,IS,IND5))          33.08
     &        +(0.25*RDY(1)) * (CAY1(ID,IS,2) * AC1(ID,IS,IND2)           33.08
     &        -                 CAY1(ID,IS,5) * AC1(ID,IS,IND5))          33.08
     &        +(0.25*RDX(2)) * (CAX1(ID,IS,3) * AC1(ID,IS,IND3)           33.08
     &        -                 CAX1(ID,IS,4) * AC1(ID,IS,IND4))          33.08
     &        +(0.25*RDY(2)) * (CAY1(ID,IS,3) * AC1(ID,IS,IND3)           33.08
     &        -                 CAY1(ID,IS,4) * AC1(ID,IS,IND4)) )        33.08
          ELSE                                                            33.09
!           spherical coordinates

            FXY2 =
     &         1.25   * RDX(1)*CAX(ID,IS,2)*AC2(ID,IS,IND2)               33.09
     &        +1.25   * RDX(2)*CAX(ID,IS,3)*AC2(ID,IS,IND3)               33.09
     &        -0.5    * RDX(1)*CAX(ID,IS,6)*AC2(ID,IS,IND6)               33.09
     &        -0.5    * RDX(2)*CAX(ID,IS,7)*AC2(ID,IS,IND7)               33.09
     &        +0.08333* RDX(1)*CAX(ID,IS,8)*AC2(ID,IS,IND8)               33.09
     &        +0.08333* RDX(2)*CAX(ID,IS,9)*AC2(ID,IS,IND9)               33.09
     &        +(0.25*RDX(1))*(CAX1(ID,IS,2)*AC1(ID,IS,IND2)               33.09
     &        -               CAX1(ID,IS,5)*AC1(ID,IS,IND5))              33.09
     &        +(0.25*RDX(2))*(CAX1(ID,IS,3)*AC1(ID,IS,IND3)               33.09
     &        -               CAX1(ID,IS,4)*AC1(ID,IS,IND4))              33.09
            FXY2 = FXY2 + (
     &        +1.25   * RDY(1)*CAY(ID,IS,2)*AC2(ID,IS,IND2)*COSLAT(2)     33.09
     &        +1.25   * RDY(2)*CAY(ID,IS,3)*AC2(ID,IS,IND3)*COSLAT(3)     33.09
     &        -0.5    * RDY(1)*CAY(ID,IS,6)*AC2(ID,IS,IND6)*COSLAT(6)     33.09
     &        -0.5    * RDY(2)*CAY(ID,IS,7)*AC2(ID,IS,IND7)*COSLAT(7)     33.09
     &        +0.08333* RDY(1)*CAY(ID,IS,8)*AC2(ID,IS,IND8)*COSLAT(8)     33.09
     &        +0.08333* RDY(2)*CAY(ID,IS,9)*AC2(ID,IS,IND9)*COSLAT(9)     33.09
     &        +(0.25*RDY(1))*(CAY1(ID,IS,2)*AC1(ID,IS,IND2)*COSLAT(2)     33.09
     &        -               CAY1(ID,IS,5)*AC1(ID,IS,IND5)*COSLAT(5))    33.09
     &        +(0.25*RDY(2))*(CAY1(ID,IS,3)*AC1(ID,IS,IND3)*COSLAT(3)     33.09
     &        -               CAY1(ID,IS,4)*AC1(ID,IS,IND4)*COSLAT(4))    33.09
     &        ) / COSLAT(1)                                               33.09
          ENDIF                                                           33.09

          IF (WAVAGE.GT.0.0) THEN      ! add the anti-GSE stuff           33.08
            D11AC = AC1(ID,IS,IND5) - 2.*AC1(ID,IS,IND1) +                33.08
     &              AC1(ID,IS,IND2)                                       33.08
            D12AC = AC1(ID,IS,IND1) - AC1(ID,IS,IND2) -                   33.08
     &              AC1(ID,IS,IND3) + AC1(ID,IS,IND10)                    33.08
            D22AC = AC1(ID,IS,IND4) - 2.*AC1(ID,IS,IND1) +                33.08
     &              AC1(ID,IS,IND3)                                       33.08
            FXY2 = FXY2 +                                                 33.08
     &          DXX * (RDX(1)*RDX(1)*D11AC + 2.*RDX(1)*RDX(2)*D12AC +     33.08
     &                 RDX(2)*RDX(2)*D22AC) +                             33.08
     &          2.*DXY * (RDX(1)*RDY(1)*D11AC + RDX(2)*RDY(2)*D22AC +     33.08
     &                (RDX(1)*RDY(2)+RDX(2)*RDY(1))*D12AC) +              33.08
     &          DYY * (RDY(1)*RDY(1)*D11AC + 2.*RDY(1)*RDY(2)*D12AC +     33.08
     &                 RDY(2)*RDY(2)*D22AC)                               33.08
            IF (ITEST.GE.120 .AND. TESTFL) WRITE (PRTEST, 6014)
     &      ID, IS, DSS, DNN, DXX, DXY, DYY, D11AC, D12AC, D22AC
 6014       FORMAT (1X, 2I4, 1X, 2E12.4, 1X, 3E12.4, 1X, 4E12.4)
          END IF                                                          33.08
!
!         *** the term FXY2 is known, store in IMATRA ***
!         *** the term FXY1 is unknown, store in IMATDA ***

!         This business of doing rollback regardless of ITERMX is an      40.08
!         artifact and has been removed.                                  40.08
          IF (ITERMX.EQ.1) THEN                                           40.08
             ACOLD = AC2(ID,IS,KCGRD(1))                                  40.08
          ELSE                                                            40.08
             ACOLD = AC1(ID,IS,KCGRD(1))                                  40.08
          ENDIF                                                           40.08
          IMATRA(ID,IS) = IMATRA(ID,IS) + FXY2 + ACOLD*RDTIM              33.08
          IMATDA(ID,IS) = IMATDA(ID,IS) + FXY1 + RDTIM                    33.08
          TRAC0(ID,IS,1) = TRAC0(ID,IS,1) - FXY2 - ACOLD*RDTIM            40.85
          TRAC1(ID,IS,1) = TRAC1(ID,IS,1) + FXY1 + RDTIM                  40.85
!
!         *** test output ***
!
          IF ( ITEST .GE. 150 .AND. TESTFL ) THEN
              WRITE(PRINTF,6021) ID, FXY1, FXY2, ACOLD
 6021         FORMAT (' - ID FXY1 FXY2 ACOLD:', I4, 3(1X,E12.4))
          ENDIF
!
 100    CONTINUE
 200  CONTINUE
!
      IF (TESTFL .AND. ITEST .GE. 100) THEN
        WRITE(PRINTF,*) '  matrix coefficients at SANDL : '
        WRITE(PRINTF,*)
     & 'IS ID IDDUM     IMATDA    IMATRA'
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE(PRINTF,2102) IS,IDDUM,ID,
     &                 IMATDA(ID,IS), IMATRA(ID,IS)
 2102       FORMAT(3I3,2E12.4)
          ENDDO
        ENDDO
      END IF
!     End of subroutine SANDL
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE STRSSI(SPCSIG  ,
     &                  CAS     ,IMAT5L  ,IMATDA  ,IMAT6U  ,ANYBIN  ,
     &                  IMATRA  ,AC2     ,ISCMIN  ,ISCMAX  ,IDDLOW  ,
     &                  IDDTOP  ,TRAC0   ,TRAC1                     )     40.85 40.41 30.21
!
!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     30.72: IJsbrand Haagsma
!     40.41: Marcel Zijlema
!     40.85: Marcel Zijlema
!
!  1. Updates
!
!     30.72, Feb. 98: Introduced generic names XCGRID, YCGRID and SPCSIG for SWAN
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     40.85, Aug. 08: store sigma-propagation for output purposes
!
!  2. Purpose
!
!     comp. of @[CAS AC2]/@S initial & boundary : IMPLICIT SCHEME
!
!  3. Method
!
!     Compute the derivative in S-direction only n the central
!     gridpoint considered:
!                             Central grid point     : IC = 1
!
!     Depending on the parameter PNUMS(7) either a central difference
!     scheme (PNUMS(7) = 0) or an upstream scheme (PNUMS(7) = 1) is
!     used. Points 1, 2 and 3 are three consecutive points on the
!     T-axis. 2 is the central point for which @(C*A)/@SIGMA and
!     @(C*W*A)/@SIGMA is computed.
!
!               1       2       3
!            ---O-------O-------O--- > SIGMA
!
!
!     PNUMS() = 0.  central difference scheme
!     PNUMS() = 1.  upwind scheme
!
!     @[CAS AC2]
!     ----------  =
!        @S
!
!     CAS(ID,IS+1,1) AC2(ID,IS+1,IX,IY) - CAS(ID,IS-1,1) AC2(ID,IS-1,IX,IY)
!     --------------------------------------------------------------------
!                                      2 DS
!
!  4. Argument variables
!
!     SPCSIG: Relative frequencies in computational domain in sigma-space 30.72
!
      REAL    SPCSIG(MSC)                                                 30.72
!
!        IC          Dummy variable: ICode gridpoint:
!                      IC = 1  Top or Bottom gridpoint
!                      IC = 2  Left or Right gridpoint
!                      IC = 3  Central gridpoint
!                    Whether which value IC has, depends of the sweep
!                    If necessary IC can be enlarged by increasing
!                    the array size of ICMAX
!        IS          Counter of relative frequency band
!        ID          Counter of directional distribution
!        ICMAX       Maximum counter for the points of the molecule
!        MXC         Maximum counter of gridpoints in x-direction
!        MYC         Maximum counter of gridpoints in y-direction
!        MSC         Maximum counter of relative frequency
!        MDC         Maximum counter of directional distribution
!                    one sweep
!
!
!        REALS:
!        ---------
!
!        DD          Width of spectral direction band
!        PNH         Equal to (1/2)*DD
!        PI          (3,14)
!
!        one and more dimensional arrays:
!        ---------------------------------
!
!        CAS     3D  Wave transport velocity in S-dirction, function of
!                    (ID,IS,IC)
!        IMATDA  2D  Coefficients of diagonal of matrix
!        IMAT5L  2D  Coefficients of lower diagonal of matrix
!        IMAT6U  2D  Coefficients of upper diagonal of matrix
!        ISCMIN  1D  Minimum counter in frequency space per direction
!        ISCMIN  1D  Maximum counter in frequency space per direction
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. Common blocks used
!
!
!        ---
!
!     8. REMARKS
!
!        ---
!
!     9. STRUCTURE
!
!   -----------------------------------------------------------
!   For every S and D-direction in direction of sweep do
!     Compute the derivative in S-direction:
!     ---------------------------------------------------------
!     Store the results of the transport terms in the
!     arrays IMATDA, IMAT5L, IMAT6U
!   -------------------------------------------------------------
!   End of STRSSI
!   ------------------------------------------------------------
!
!     10. SOURCE
!
!****************************************************************
!
      INTEGER  IENT, IS      ,ID      ,IDDLOW  ,IDDTOP  ,IDDUM
!
      REAL     DS      ,PNH     ,PN1     ,PN2     ,C1      ,C2      ,
     &         C3      ,A1      ,A3      ,PCD1    ,PCD2    ,RHS12   ,
     &         RHS23   ,DIAG12  ,DIAG23
      REAL     TC12    ,TC23    ,S1      ,S3
!
      LOGICAL  BIN1    ,BIN3
!
      REAL     AC2(MDC,MSC,MCGRD)         ,
     &         CAS(MDC,MSC,ICMAX)         ,
     &         IMAT5L(MDC,MSC)            ,
     &         IMATDA(MDC,MSC)            ,
     &         IMAT6U(MDC,MSC)            ,
     &         IMATRA(MDC,MSC)
      REAL  :: TRAC0(MDC,MSC,MTRNP)                                       40.85
      REAL  :: TRAC1(MDC,MSC,MTRNP)                                       40.85
!
      INTEGER  ISCMIN(MDC)                ,
     &         ISCMAX(MDC)
!
      LOGICAL  ANYBIN(MDC,MSC)
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'STRSSI')
!
      DO 500 IDDUM = IDDLOW, IDDTOP
        ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
        IF (ISCMIN(ID).EQ.0) GOTO 500
        DO 400 IS = ISCMIN(ID), ISCMAX(ID)
          A1 = 0.
          A3 = 0.
          C2 = CAS(ID,IS,1)
          IF ( IS .EQ. 1 ) THEN
            C1   = 0.
            A1   = 0.
            BIN1 = .FALSE.
            C3   = CAS(ID,IS+1,1)
            BIN3 = ANYBIN(ID,IS+1)
            IF (.NOT.BIN3) A3 = AC2(ID,IS+1,KCGRD(1))                     30.21
            DS   = SPCSIG(IS+1) - SPCSIG(IS)                              30.72
            S1 = 0.                                                       40.85
            S3 = SPCSIG(IS+1)                                             40.85
          ELSE IF ( IS .EQ. MSC ) THEN
            C1   = CAS(ID,IS-1,1)
            BIN1 = ANYBIN(ID,IS-1)
            IF (.NOT.BIN1) A1 = AC2(ID,IS-1,KCGRD(1))                     30.21
            C3   = C2
            A3   = 0.
            BIN3 = .FALSE.
            DS   = SPCSIG(IS) - SPCSIG(IS-1)                              30.72
            S1 = SPCSIG(IS-1)                                             40.85
            S3 = 0.                                                       40.85
          ELSE
            C1   = CAS(ID,IS-1,1)
            C3   = CAS(ID,IS+1,1)
            BIN1 = ANYBIN(ID,IS-1)
            BIN3 = ANYBIN(ID,IS+1)
            IF (.NOT.BIN1) A1 = AC2(ID,IS-1,KCGRD(1))                     30.21
            IF (.NOT.BIN3) A3 = AC2(ID,IS+1,KCGRD(1))                     30.21
            DS   = 0.5 * ( SPCSIG(IS+1) - SPCSIG(IS-1) )                  30.72
            S1 = SPCSIG(IS-1)                                             40.85
            S3 = SPCSIG(IS+1)                                             40.85
          END IF
!
          PNH = 1. / (2. * DS)
          PN1 =  (1. - PNUMS(7) ) * PNH
          PN2 =  (1. + PNUMS(7) ) * PNH
!
!         *** fill the lower diagonal and the diagonal ***
!
          IF ( C1 .GT. 1.E-8 .AND. C2 .GT. 1.E-8 ) THEN
            PCD1 = PN2 * C1
            PCD2 = PN1 * C2
          ELSE IF ( C1 .LT. -1.E-8 .AND. C2 .LT. -1.E-8 ) THEN
            PCD1 = PN1 * C1
            PCD2 = PN2 * C2
          ELSE
            PCD1 = PNH * C1
            PCD2 = PNH * C2
          END IF
!
          RHS12 = 0.
          TC12  = 0.
          IF ( IS .EQ. 1 .AND. C2.LT.0.) THEN
!           fully upwind approximation at the boundary of the frequency space
            DIAG12 = - PCD1 - PCD2
          ELSE
            DIAG12 = - PCD2
            IF (BIN1) THEN
              IMAT5L(ID,IS) = IMAT5L(ID,IS) - PCD1
            ELSE
              RHS12 = PCD1 * A1
              TC12  = RHS12* S1
            ENDIF
          ENDIF
!
          IF ( C2 .GT. 1.E-8 .AND. C3 .GT. 1.E-8 ) THEN
            PCD2 = PN2 * C2
            PCD3 = PN1 * C3
          ELSE IF ( C2 .LT. -1.E-8 .AND. C3 .LT. -1.E-8 ) THEN
            PCD2 = PN1 * C2
            PCD3 = PN2 * C3
          ELSE
            PCD2 = PNH * C2
            PCD3 = PNH * C3
          END IF
!
          RHS23 = 0.
          TC23  = 0.
          IF (IS .EQ. MSC .AND. C2.GT.0.) THEN
!           full upwind approximation at the boundary
            DIAG23 = PCD2 + PCD3
          ELSE
            DIAG23 = PCD2
            IF (BIN3) THEN
              IMAT6U(ID,IS) = IMAT6U(ID,IS) + PCD3
            ELSE
              RHS23 = - PCD3 * A3
              TC23  = RHS23 * S3
            ENDIF
          ENDIF
          IMATDA(ID,IS) = IMATDA(ID,IS) + DIAG12 + DIAG23
          IMATRA(ID,IS) = IMATRA(ID,IS) + RHS12 + RHS23
          TRAC0(ID,IS,3) = TRAC0(ID,IS,3) - TC12 - TC23                   40.85
          TRAC1(ID,IS,3) = TRAC1(ID,IS,3) + DIAG12 + DIAG23               40.85
400     CONTINUE
500   CONTINUE
!
!     *** test output ***
!
      IF ( TESTFL .AND. ITEST .GE. 35 ) THEN
        WRITE(PRINTF,111) KCGRD(1), IDDLOW, IDDTOP
 111    FORMAT(' STRSSI: POINT IDDLOW IDDTOP  :',3I5)
        WRITE(PRINTF,131) PNUMS(7)
 131    FORMAT(' STRSSI: CSS                  :',2E12.4)
        WRITE(PRINTF,*)
        WRITE(PRINTF,*) ' matrix coefficients in STRSSI'
        WRITE(PRINTF,*)
        WRITE(PRINTF,*)
     & '   IS   ID    IMAT5L       IMATDA       IMAT6U    IMATRA    CAS'
        DO IDDUM = IDDLOW, IDDTOP
          ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
          IF (ISCMIN(ID).GT.0) THEN
            DO IS = ISCMIN(ID), ISCMAX(ID)
              WRITE(PRINTF,2101) IS, ID, IMAT5L(ID,IS),IMATDA(ID,IS),
     &                         IMAT6U(ID,IS),IMATRA(ID,IS),CAS(ID,IS,1)
2101          FORMAT(1X,2I4,4X,4E12.4,E10.2)
            ENDDO
          ENDIF
        ENDDO
      END IF
!
!     End of subroutine STRSSI
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE STRSSB (IDDLOW  ,IDDTOP  ,
     &                   IDCMIN  ,IDCMAX  ,ISSTOP  ,CAX     ,CAY     ,
     &                   CAS     ,AC2     ,SPCSIG  ,IMATRA  ,
     &                   ANYBLK  ,RDX     ,RDY     ,TRAC0            )    41.07 40.41 30.21
!
!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     30.72: IJsbrand Haagsma
!     40.41: Marcel Zijlema
!     41.07: Marcel Zijlema
!
!  1. Updates
!
!     30.72, Feb. 98: Introduced generic names XCGRID, YCGRID and SPCSIG for SWAN
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     41.07, Jul. 09: also central scheme blended with upwind scheme
!
!  2. Purpose
!
!     comp. of @[CAS AC2]/@S initial & boundary with an explicit
!     scheme. The energy near the blocking point is removed
!     from the spectrum based on a CFL criterion
!
!     The frequencies beyond ISSTOP are blocked in a 1-D situation
!     For a 2-D case the situation is somewhat more complicated (
!     see below)
!
!
!        ^  |                       1-D case
!     E()|  |          *            ========
!           |        *   *
!           |              *
!           |       *        *      / blocking frequency
!           |                .... /
!           |      *         ....| *
!           |        SWEEP 1 ....| o o *
!           |     *          ....| o o o o o*
!          0---------------------|-----------|---------
!           0                  ISSTOP       MSC   --> s
!
!                           -|---|-
!                              ^
!                              |---- CFL > 0.5sqrt(2) -> ANYBLK = true
!
!
!               ANYBIN = TRUE     ANYBIN = FALSE
!           |--------------------|-----------|
!
!
!  3. Method
!
!     Compute the derivative in s-direction:
!     The nearby points are indicated with the index IC (see
!     FUNCTION ICODE(_,_):
!     Central grid point     : IC = 1
!     Point in X-direction   : IC = 2
!     Point in Y-direction   : IC = 3
!
!     @[CAS AC2]
!     --------- =
!        @S
!
!     CAS*AC2(ID,IS) - CAS*AC2(ID,IS-1)     F(IS+0.5) - F(IS-0.5)
!     ---------------------------------- = -----------------------
!                   DS                                DS
!
!                  /  CAS(IS+0.5) * ( (1-0.5mu)*AC2(IS+1) + 0.5mu*AC2(IS) )    IF CAS(IS+0.5) < 0
!     F(IS+0.5) =  |
!                  \  CAS(IS+0.5) * ( (1-0.5mu)*AC2(IS) + 0.5mu*AC2(IS+1) )    IF CAS(IS+0.5) > 0
!
!                  /  CAS(IS-0.5) * ( (1-0.5mu)*AC2(IS-1) + 0.5mu*AC2(IS) )    IF CAS(IS-0.5) > 0
!     F(IS-0.5) =  |
!                  \  CAS(IS-0.5) * ( (1-0.5mu)*AC2(IS) + 0.5mu*AC2(IS-1) )    IF CAS(IS-0.5) < 0
!
!     with
!
!           0 <= mu <= 1 a blending factor
!
!           mu = 0 corresponds to 1st order upwind scheme
!           mu = 1 corresponds to 2nd order central scheme
!
!           default value, mu = 0.5
!
!    and
!
!           CAS(IS+0.5) = ( CAS(IS+1) + CAS(IS) ) / 2.
!
!           CAS(IS-0.5) = ( CAS(IS) + CAS(IS-1) ) / 2.
!
!
!     ------------------------------------------------------------
!     Courant-Friedlich-Levich criterion :
!
!                  | Cs |
!                  | -- |
!                  | ds |         <
!               ---------------   =  0.5 * sqrt(2.0)
!      CFL  =  | Cx |   | Cy |
!              | -- | + | -- |
!              | dx |   | dy |
!
!     For a bin in which the CFL criterion is larger two
!     ways are possible:
!
!            1)  Cs can be limited
!            2)  Action in bin can be set equal zero
!
!     --------------------------------------------------------------
!
!  4. Argument variables
!
!     SPCSIG: Relative frequencies in computational domain in sigma-space 30.72
!
      REAL    SPCSIG(MSC)                                                 30.72
!
!        IC          Dummy variable: ICode gridpoint:
!                      IC = 1  Top or Bottom gridpoint
!                      IC = 2  Left or Right gridpoint
!                      IC = 3  Central gridpoint
!                    Whether which value IC has, depends of the sweep
!                    If necessary IC can be enlarged by increasing
!                    the array size of ICMAX
!        IX          Counter of gridpoints in x-direction
!        IY          Counter of gridpoints in y-direction
!        IS          Counter of relative frequency band
!        ID          Counter of directional distribution
!        ICMAX       Maximum counter for the points of the molecule
!        MXC         Maximum counter of gridpoints in x-direction
!        MYC         Maximum counter of gridpoints in y-direction
!        MSC         Maximum counter of relative frequency
!        MDC         Maximum counter of directional distribution
!        ISSTOP      Maximum frequency counter for wave components
!                    that are propagated within a sweep
!        IDDLOW      Minimum direction that is propagated within a
!                    sweep
!        IDDTOP      Idem maximum
!
!        REALS:
!        ---------
!
!        FSA_        Dummy variable
!
!        one and more dimensional arrays:
!        ---------------------------------
!
!        AC2     4D  Action density as function of D,S,X,Y at time T
!        CAS     3D  Wave transport velocity in S-dirction, function of
!                    (ID,IS,IC)
!        CAX, CAY    Propagation velocities in x-y space
!        IMATRA  2D  Coefficients of right hand side of matrix
!        ISCMIN  1D  Diractional dependent counter
!        ISCMIN  1D  Directional dependent counter
!        ANYBLK  2D  Determines if a bin is BLOCKED by a counter current
!                    based on a CFL criterion
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. Common blocks used
!
!
!     8. REMARKS
!
!        ---
!
!     9. STRUCTURE
!
!   ------------------------------------------------------------
!   For every S and D-direction in direction of sweep do,
!     Determine if CFL criterion is satisfied
!     Compute the derivative in s-direction:
!     ---------------------------------------------------------
!     Compute transportation terms
!     Store the terms in the array IMATRA
!   -------------------------------------------------------------
!   End of STRSSB
!   -------------------------------------------------------------
!
!     10. SOURCE
!
!************************************************************************
!
      INTEGER  IENT, IS      ,ID      ,ISSTOP  ,
     &         IDDLOW  ,IDDTOP  ,IDDUM
!
      REAL     FSA     ,FLEFT   ,FRGHT   ,DS      ,CFLMAX  ,CFLCEN  ,
     &         CAXCEN  ,CAYCEN  ,CASCEN  ,TX      ,TY      ,TS      ,
     &         CASL    ,CASR    ,PN1     ,PN2
!
      REAL     CAS(MDC,MSC,ICMAX)       ,
     &         CAX(MDC,MSC,ICMAX)       ,
     &         CAY(MDC,MSC,ICMAX)       ,
     &         AC2(MDC,MSC,MCGRD)       ,
     &         IMATRA(MDC,MSC)          ,
     &         RDX(MICMAX)              ,                                 40.08
     &         RDY(MICMAX)                                                40.08
      REAL  :: TRAC0(MDC,MSC,MTRNP)                                       41.07
!
      INTEGER  IDCMIN(MSC)              ,
     &         IDCMAX(MSC)
!
      LOGICAL  ANYBLK(MDC,MSC)
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'STRSSB')
!
!     --- determine blending factor
!
      PN1 = 0.5*(1.+PNUMS(7))                                             41.07
      PN2 = 0.5*(1.-PNUMS(7))                                             41.07
!
!     *** initialization of ANYBLK and CFLMAX value ***
!
      DO IS = 1, MSC
        DO ID = 1, MDC
          ANYBLK(ID,IS) = .FALSE.
        ENDDO
      ENDDO
      CFLMAX = PNUMS(19)
!
      DO IS = 1, ISSTOP
        IF ( IS .EQ. 1 ) THEN
          DS = SPCSIG(IS+1) - SPCSIG(IS)                                  30.72
        ELSE IF ( IS .EQ. MSC ) THEN
          DS = SPCSIG(IS) - SPCSIG(IS-1)                                  30.72
        ELSE
          DS = 0.5 * ( SPCSIG(IS+1) - SPCSIG(IS-1) )                      30.72
        END IF
        DO IDDUM = IDCMIN(IS), IDCMAX(IS)
          ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
          CAXCEN = ABS ( CAX(ID,IS,1) )
          CAYCEN = ABS ( CAY(ID,IS,1) )
          CASCEN = ABS ( CAS(ID,IS,1) )
!
          TX     = RDX(1) * CAXCEN + RDX(2) * CAXCEN
          TY     = RDY(1) * CAYCEN + RDY(2) * CAYCEN
!
          TS     = CASCEN / DS
          CFLCEN = TS / MAX( 1.E-20 , ( TX + TY ) )
          FRGHT = 0.
          FLEFT = 0.
!
!         *** check if a bin can be propagated or if it is blocked ***
!
          IF ( CFLCEN .GT. CFLMAX ) THEN
!
!           *** de-activate bin in solver by ANYBLK ***
!
            ANYBLK(ID,IS) = .TRUE.
!
          ELSE
!
!           *** calculate transport in frequency space ***
!
            IF ( IS .EQ. 1 ) THEN
!             *** for first point an upwind scheme is used ***
              CASR  = 0.5 * ( CAS(ID,IS,1) + CAS(ID,IS+1,1) )
              IF ( CASR .LT. 0. ) THEN
                FRGHT = CASR * AC2(ID,IS+1,KCGRD(1))                      30.21
              ELSE
                FRGHT = CASR * AC2(ID,IS  ,KCGRD(1))                      30.21
              END IF
              FLEFT = 0.
            ELSE IF ( IS .EQ. MSC ) THEN
!             *** for the last discrete point in frequency space ***
!             *** an upwind scheme is used                       ***
              CASL = CAS(ID,IS-1,1)
              CASR = CAS(ID,IS  ,1)
              IF ( CASL .LT. 0. ) THEN
                FLEFT = CASL * AC2(ID,IS  ,KCGRD(1))                      30.21
              ELSE
                FLEFT = CASL * AC2(ID,IS-1,KCGRD(1))                      30.21
              END IF
              IF ( CASR .LT. 0. ) THEN
!               *** assumption has been made that the flux is ***
!               *** zero for the bin beyond MSC               ***
                FRGHT = 0.
              ELSE
                FRGHT = CASR * AC2(ID,IS,KCGRD(1))                        30.21
              END IF
            ELSE
!             *** point in frequency range ***
              CASL  = 0.5 * ( CAS(ID,IS,1) + CAS(ID,IS-1,1) )
              CASR  = 0.5 * ( CAS(ID,IS,1) + CAS(ID,IS+1,1) )
              IF ( CASL .LT. 0. ) THEN
                FLEFT = CASL * ( PN1*AC2(ID,IS  ,KCGRD(1)) +              41.07
     &                           PN2*AC2(ID,IS-1,KCGRD(1)) )              41.07 30.21
              ELSE
                FLEFT = CASL * ( PN1*AC2(ID,IS-1,KCGRD(1)) +              41.07
     &                           PN2*AC2(ID,IS  ,KCGRD(1)) )              41.07 30.21
              END IF
              IF ( CASR .LT. 0. ) THEN
                FRGHT = CASR * ( PN1*AC2(ID,IS+1,KCGRD(1)) +              41.07
     &                           PN2*AC2(ID,IS  ,KCGRD(1)) )              41.07 30.21
              ELSE
                FRGHT = CASR * ( PN1*AC2(ID,IS  ,KCGRD(1)) +              41.07
     &                           PN2*AC2(ID,IS+1,KCGRD(1)) )              41.07 30.21
              END IF
            END IF
!
            FSA  = ( FRGHT - FLEFT ) / DS
!
!           *** all the terms are known, store in IMATRA ***
!
            IMATRA(ID,IS) = IMATRA(ID,IS) - FSA
            TRAC0(ID,IS,3) = TRAC0(ID,IS,3) + FSA                         41.07
          ENDIF
!
!         *** test output ***

          IF ( ITEST .GE. 50 .AND. TESTFL ) THEN
            WRITE(PRINTF,670) IS,ID,FRGHT,FLEFT,CFLCEN,ANYBLK(ID,IS)
 670        FORMAT(' STRSSB: FR FL CFLC ANYBLK:',2I3,3E12.4,L3)
          END IF

!
        ENDDO
      ENDDO
!
!     *** test output ***
!
      IF ( ITEST .GE. 50 .AND. TESTFL ) THEN
        WRITE(PRINTF,200) MDC,MSC,MCGRD
 200    FORMAT(' BLOCKB : MDC MSC MCGRD    : ',3I5)
        WRITE(PRINTF,300) KCGRD(1), ISSTOP, CFLMAX
 300    FORMAT(' BLOCKB : POINT ISSTOP CFLMAX: ',2I5,F8.4)
        WRITE(PRINTF,400) IDDLOW, IDDTOP
 400    FORMAT (' Active bins within a sweep  -> ID: ',I3,' to ',I3)
        WRITE(PRINTF,*)
        WRITE(PRINTF,*)(' Propagation of bin if blocking can occur')
        WRITE(PRINTF,*)('   1) No blocking of bin -> ANYBLK = .F.')
        WRITE(PRINTF,*)('   2) Blocking of bin    -> ANYBLK = .T.')
        WRITE(PRINTF,*)
        DO IDDUM = IDDTOP+1, IDDLOW-1, -1
          ID = MOD ( IDDUM - 1 + MDC, MDC) + 1
            WRITE(PRINTF,500) ID, (ANYBLK(ID,IS),IS=1,MIN(ISSTOP,25))
 500        FORMAT(I4,25L3)
        ENDDO
        WRITE(PRINTF,600)(IS, IS=1+4, MIN(ISSTOP,25), 5 )
 600    FORMAT(6X,'1',9X,5(I3,12X))
        WRITE(PRINTF,*)
!
      ENDIF
!
!     End of subroutine STRSSB
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE STRSD (DD      ,IDCMIN  ,
     &                  IDCMAX  ,CAD     ,IMATLA  ,IMATDA  ,IMATUA  ,
     &                  IMATRA  ,AC2     ,ISSTOP  ,
     &                  ANYBIN  ,LEAKC1  ,TRAC0   ,TRAC1            )     40.85 40.41 30.21

!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!     1. UPDATE
!
!        40.41, Oct. 04: common blocks replaced by modules, include files removed
!        40.85, Aug. 08: store theta-propagation for output purposes
!
!     2. PURPOSE
!
!        comp. of @[CAD AC2]/@D initial & boundary
!
!     3. METHOD
!
!        Compute the derivative in D-direction only n the central
!        gridpoint considered:
!                                Central grid point     : IC = 1
!
!       Depending on the parameter PNUMS(6) either a central difference
!       scheme (PNUMS(6) = 0) or an upstream scheme (PNUMS(6) = 1) is
!       used. Points 1, 2 and 3 are three consecutive points on the
!       T-axis. 2 is the central point for which @(C*A)/@THETA and
!       @(C*W*A)/@THETA is computed.
!
!                 1       2       3
!              ---O-------O-------O--- > THETA
!
!
!        PNUMS() = 0.  central difference scheme
!        PNUMS() = 1.  upwind scheme
!
!        @[CAD AC2]
!        ----------  =
!           @D
!
!        CAD(ID+1,IS,1) AC2(ID+1,IS,IX,IY) - CAD(ID-1,IS,1) AC2(ID-1,IS,IX,IY)
!        --------------------------------------------------------------------
!                                         2*DD
!
!     4. PARAMETERLIST
!
!        IC          Dummy variable: ICode gridpoint:
!                      IC = 1  Top or Bottom gridpoint
!                      IC = 2  Left or Right gridpoint
!                      IC = 3  Central gridpoint
!                    Whether which value IC has, depends of the sweep
!                    If necessary IC can be enlarged by increasing
!                    the array size of ICMAX
!        IS          Counter of relative frequency band
!        ID          Counter of directional distribution
!        ICMAX       Maximum counter for the points of the molecule
!        MXC         Maximum counter of gridpoints in x-direction
!        MYC         Maximum counter of gridpoints in y-direction
!        MSC         Maximum counter of relative frequency
!        MDC         Maximum counter of directional distribution
!        FULCIR      logical: if true, computation on a full circle
!
!        REALS:
!        ---------
!
!        DD          Width of spectral direction band
!        PNH         Equal to (1/2)*DD
!        PI          (3,14)
!
!        one and more dimensional arrays:
!        ---------------------------------
!
!        CAD     3D  Wave transport velocity in S-dirction, function of
!                    (ID,IS,IC)
!        IMATDA  2D  Coefficients of diagonal of matrix
!        IMATLA  2D  Coefficients of lower diagonal of matrix
!        IMATUA  2D  Coefficients of upper diagonal of matrix
!        IDCMIN  1D  frequency dependent counter
!        IDCMIN  1D  frequency dependent counter
!        ANYBIN  2D  see subr SWPSEL
!        LEAKC1  2D  leak coefficient
!
!     5. SUBROUTINES CALLING
!
!        ACTION
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. Common blocks used
!
!
!     8. REMARKS
!
!        ---
!
!     9. STRUCTURE
!
!   -----------------------------------------------------------
!   For every S and D-direction in direction of sweep do
!     Compute the derivative in D-direction:
!     ---------------------------------------------------------
!     Store the results of the transport terms in the
!     arrays IMATDA, IMATLA, IMATUA
!   -------------------------------------------------------------
!   End of STRSD
!   ------------------------------------------------------------
!
!     10. SOURCE
!
!****************************************************************
!
      LOGICAL  BIN1, BIN2, BIN3
!
      INTEGER  IENT  ,IS    ,ID    ,IIDM  ,IIDP  ,
     &         ISSTOP,IDDUM
!
      REAL     DD    ,PNH   ,PN1   ,PN2
!
      REAL     AC2(MDC,MSC,MCGRD)         ,                               30.21
     &         CAD(MDC,MSC,ICMAX)         ,
     &         IMATLA(MDC,MSC)            ,
     &         IMATDA(MDC,MSC)            ,
     &         IMATUA(MDC,MSC)            ,
     &         IMATRA(MDC,MSC)            ,
     &         LEAKC1(MDC,MSC)
      REAL  :: TRAC0(MDC,MSC,MTRNP)                                       40.85
      REAL  :: TRAC1(MDC,MSC,MTRNP)                                       40.85
!
      INTEGER  IDCMIN(MSC)                ,
     &         IDCMAX(MSC)
!
      LOGICAL  ANYBIN(MDC,MSC)
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'STRSD')
!
      PNH = 1. / (2. * DD)
      PN1 =  (1. - PNUMS(6) ) * PNH
      PN2 =  (1. + PNUMS(6) ) * PNH
!
      DO 200 IS = 1, ISSTOP
        DO 100 IDDUM = IDCMIN(IS), IDCMAX(IS)
          ID = MOD (IDDUM-1+MDC, MDC) + 1
          C2 = CAD(ID,IS,1)
          BIN2 = ANYBIN(ID,IS)
          IF (BIN2) THEN
            IF (FULCIR .OR. ID.GT.1) THEN
              IIDM = MOD (IDDUM-2+MDC, MDC) + 1
              C1   = CAD(IIDM,IS,1)
              BIN1 = ANYBIN(IIDM,IS)
              IF (.NOT.BIN1) A1 = AC2(IIDM,IS,KCGRD(1))
            ELSE
              IIDM = 0
              C1   = C2
              BIN1 = .FALSE.
              A1   = 0.
            ENDIF
            IF (FULCIR .OR. ID.LT.MDC) THEN
              IIDP = MOD (IDDUM+MDC, MDC) + 1
              C3   = CAD(IIDP,IS,1)
              BIN3 = ANYBIN(IIDP,IS)
              IF (.NOT.BIN3) A3 = AC2(IIDP,IS,KCGRD(1))                   30.21
            ELSE
              IIDP = 0
              C3   = C2
              BIN3 = .FALSE.
              A3   = 0.
            ENDIF
!
!           *** fill the lower diagonal and the diagonal ***
!
            IF ( C1 .GT. 1.E-8 .AND. C2 .GT. 1.E-8 ) THEN
              PCD1 = PN2 * C1
              PCD2 = PN1 * C2
            ELSE IF ( C1 .LT. -1.E-8 .AND. C2 .LT. -1.E-8 ) THEN
              PCD1 = PN1 * C1
              PCD2 = PN2 * C2
            ELSE
              PCD1 = PNH * C1
              PCD2 = PNH * C2
            END IF
!
            RHS12 = 0.
            IF (IIDM.EQ.0 .AND. C2.LT.0.) THEN
!             fully upwind approximation at the boundary of the directional
!             sector
              DIAG12 = - PCD1 - PCD2
              LEAKC1(ID,IS) = -C2
            ELSE
              DIAG12 = - PCD2
              IF (BIN1) THEN
                IMATLA(ID,IS) = IMATLA(ID,IS) - PCD1
              ELSE
                RHS12 = PCD1 * A1
              ENDIF
            ENDIF
!
            IF ( C2 .GT. 1.E-8 .AND. C3 .GT. 1.E-8 ) THEN
              PCD2 = PN2 * C2
              PCD3 = PN1 * C3
            ELSE IF ( C2 .LT. -1.E-8 .AND. C3 .LT. -1.E-8 ) THEN
              PCD2 = PN1 * C2
              PCD3 = PN2 * C3
            ELSE
              PCD2 = PNH * C2
              PCD3 = PNH * C3
            END IF
!
            RHS23 = 0.
            IF (IIDP.EQ.0 .AND. C2.GT.0.) THEN
!             full upwind approximation at the boundary
              DIAG23 = PCD2 + PCD3
              LEAKC1(ID,IS) = C2
            ELSE
              DIAG23 = PCD2
              IF (BIN3) THEN
                IMATUA(ID,IS) = IMATUA(ID,IS) + PCD3
              ELSE
                RHS23 = - PCD3 * A3
              ENDIF
            ENDIF
            IMATDA(ID,IS) = IMATDA(ID,IS) + DIAG12 + DIAG23
            IMATRA(ID,IS) = IMATRA(ID,IS) + RHS12 + RHS23
            TRAC0(ID,IS,2) = TRAC0(ID,IS,2) - RHS12 - RHS23               40.85
            TRAC1(ID,IS,2) = TRAC1(ID,IS,2) + DIAG12 + DIAG23             40.85
          ENDIF
!
 100    CONTINUE
 200  CONTINUE
!
!     *** test output
!
      IF ( ITEST .GE. 80 .AND. TESTFL ) THEN
        WRITE(PRINTF,5001) FULCIR
5001    FORMAT (' FULL CIRCLE                   ',L4)
        WRITE(PRINTF,6021) KCGRD(1), ISSTOP, PNUMS(6)                     30.21
6021    FORMAT (' STRSD :POINT ISTOP CDD      :',2I5,E12.4)
        WRITE(PRINTF,5021) PN1, PN2, PNH ,DD
5021    FORMAT (' STRSD : PN1 PN2 PNH DD      :',4E12.4)
      END IF
!
!     End of subroutine STRSD
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE STRSDFV (DD      ,IDCMIN  ,
     &                    IDCMAX  ,CAD     ,IMATLA  ,IMATDA  ,IMATUA  ,
     &                    IMATRA  ,AC2     ,ISSTOP  ,
     &                    ANYBIN  ,LEAKC1  ,TRAC0   ,TRAC1            )   40.85
!
!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering and Geosciences              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmer: Marcel Zijlema                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     40.23: Marcel Zijlema
!     40.41: Marcel Zijlema
!     40.85: Marcel Zijlema
!
!  1. Updates
!
!     40.23, Nov. 02: New subroutine
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     40.85, Aug. 08: store theta-propagation for output purposes
!
!  2. Purpose
!
!     computation of @[CAD AC2]/@D based on finite volume method
!
!  4. Argument variables
!
!     AC2         action density
!     ANYBIN      logical: indicate whether current bin is selected
!     CAD         wave transport velocity in D-direction
!     DD          width of spectral direction band
!     IDCMAX      frequency dependent counter
!     IDCMIN      frequency dependent counter
!     IMATDA      coefficients of diagonal of matrix
!     IMATLA      coefficients of lower diagonal of matrix
!     IMATRA      coefficients of right hand side
!     IMATUA      coefficients of upper diagonal of matrix
!     ISSTOP      maximum frequency counter in a sweep
!     LEAKC1      leak coefficient
!     TRAC0       transport coefficient for output
!     TRAC1       transport coefficient for output
!
      INTEGER ISSTOP
      INTEGER IDCMIN(MSC), IDCMAX(MSC)
      REAL    DD
      REAL    AC2(MDC,MSC,MCGRD),
     &        CAD(MDC,MSC,ICMAX),
     &        IMATLA(MDC,MSC)   ,
     &        IMATDA(MDC,MSC)   ,
     &        IMATUA(MDC,MSC)   ,
     &        IMATRA(MDC,MSC)   ,
     &        LEAKC1(MDC,MSC)
      REAL    TRAC0(MDC,MSC,MTRNP)
      REAL    TRAC1(MDC,MSC,MTRNP)
      LOGICAL ANYBIN(MDC,MSC)
!
!  6. Local variables
!
!     ACM   :     lower action
!     ACP   :     upper action
!     BINM  :     indicate whether lower bin is selected
!     BINP  :     indicate whether upper bin is selected
!     CADM  :     lower wave transport velocity
!     CADP  :     upper wave transport velocity
!     CAN   :     negative wave transport velocity
!     CAP   :     positive wave transport velocity
!     CAV   :     averaged wave transport velocity; may be
!                 regarded as flux velocity
!     DDI   :     inverse of width of spectral direction band
!     ID    :     counter
!     IDDUM :     loop counter
!     IDM   :     index of point ID-1
!     IDP   :     index of point ID+1
!     IENT  :     number of entries
!     IS    :     loop counter
!     MU    :     blending parameter in between 0 and 1
!                 =0; central differences
!                 =1; first order upwind
!
      INTEGER IENT, ID, IDM, IDP, IDDUM, IS
      REAL    ACM, ACP, CADM, CADP,
     &        CAN, CAP, CAV, DDI, MU
      LOGICAL BINM, BINP
!
!  8. Subroutines used
!
!     STRACE           Tracing routine for debugging
!
!  9. Subroutines calling
!
!     ACTION (in SWANCOM1)
!
! 12. Structure
!
!     For every S and D-direction in direction of sweep do
!
!        Compute the derivative in D-direction and
!        store the results of this calculation in the
!        arrays IMATDA, IMATLA, IMATUA and IMATRA
!
! 13. Source text
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'STRSDFV')

      DDI = 1./DD
      MU  = PNUMS(6)

      DO 20 IS = 1, ISSTOP

         DO 10 IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD (IDDUM-1+MDC, MDC) + 1

            IF ( ANYBIN(ID,IS) ) THEN

               IF ( IDDUM.EQ.IDCMIN(IS) ) THEN

                  IF ( FULCIR .OR. ID.GT.1 ) THEN
                     IDM  = MOD (IDDUM-2+MDC, MDC) + 1
                     CADM = CAD(IDM,IS,1)
                     BINM = ANYBIN(IDM,IS)
                     IF (.NOT.BINM) ACM = AC2(IDM,IS,KCGRD(1))
                  ELSE
                     IDM  = 0
                     CADM = CAD(ID,IS,1)
                     BINM = .FALSE.
                     ACM  = 0.
                  END IF

                  CAV = 0.5*(CAD(ID,IS,1) + CADM)
                  CAP = 0.5*(CAV + ABS(CAV))
                  CAN = 0.5*(CAV - ABS(CAV))
!
!                 put them in blended form
                  CAP = CAP*MU + 0.5*CAV*(1.-MU)
                  CAN = CAN*MU + 0.5*CAV*(1.-MU)

                  IF ( .NOT.BINM ) THEN
                     IMATDA(ID,IS) = IMATDA(ID,IS)  - DDI * CAN
                     IMATRA(ID,IS) = IMATRA(ID,IS)  + DDI * CAP * ACM
                     TRAC0(ID,IS,2) = TRAC0(ID,IS,2) - DDI * CAP * ACM    40.85
                     TRAC1(ID,IS,2) = TRAC1(ID,IS,2) - DDI * CAN          40.85
                  END IF

                  IF ( IDM.EQ.0 ) LEAKC1(ID,IS) = -CAN

               END IF

               IF ( FULCIR .OR. ID.LT.MDC ) THEN
                  IDP  = MOD (IDDUM+MDC, MDC) + 1
                  CADP = CAD(IDP,IS,1)
                  BINP = ANYBIN(IDP,IS)
                  IF (.NOT.BINP) ACP = AC2(IDP,IS,KCGRD(1))
               ELSE
                  IDP  = 0
                  CADP = CAD(ID,IS,1)
                  BINP = .FALSE.
                  ACP  = 0.
               END IF

               CAV = 0.5*(CAD(ID,IS,1) + CADP)
               CAP = 0.5*(CAV + ABS(CAV))
               CAN = 0.5*(CAV - ABS(CAV))
!
!              put them in blended form
               CAP = CAP*MU + 0.5*CAV*(1.-MU)
               CAN = CAN*MU + 0.5*CAV*(1.-MU)

               IF ( BINP ) THEN
                  IMATDA(ID ,IS) = IMATDA(ID ,IS) + DDI * CAP
                  IMATUA(ID ,IS) = IMATUA(ID ,IS) + DDI * CAN
                  IMATDA(IDP,IS) = IMATDA(IDP,IS) - DDI * CAN
                  IMATLA(IDP,IS) = IMATLA(IDP,IS) - DDI * CAP
                  TRAC1(ID ,IS,2) = TRAC1(ID ,IS,2) + DDI * CAP           40.85
                  TRAC1(IDP,IS,2) = TRAC1(IDP,IS,2) - DDI * CAN           40.85
               ELSE
                  IMATDA(ID,IS) = IMATDA(ID,IS) + DDI * CAP
                  IMATRA(ID,IS) = IMATRA(ID,IS) - DDI * CAN * ACP
                  TRAC0(ID,IS,2) = TRAC0(ID,IS,2) + DDI * CAN * ACP       40.85
                  TRAC1(ID,IS,2) = TRAC1(ID,IS,2) + DDI * CAP             40.85
               END IF

               IF ( IDP.EQ.0 ) LEAKC1(ID,IS) = CAP

            END IF

 10      CONTINUE
 20   CONTINUE
!
!     --- test output
!
      IF ( TESTFL .AND. ITEST.GE.80 ) THEN
         WRITE(PRINTF,111) KCGRD(1), ISSTOP
111      FORMAT(' STRSDFV: POINT  ISSTOP  :',2I5)
         WRITE(PRINTF,222) PNUMS(6)
222      FORMAT(' STRSDFV: CDD            :',E12.4)
         WRITE(PRINTF,*)
         WRITE(PRINTF,*) ' matrix coefficients in STRSDFV'
         WRITE(PRINTF,*)
         WRITE(PRINTF,*)
     &'   IS ID      IMATLA      IMATDA      IMATUA      IMATRA     CAD'
         DO IS = 1, ISSTOP
            DO IDDUM = IDCMIN(IS), IDCMAX(IS)
               ID = MOD (IDDUM-1+MDC, MDC) + 1
               WRITE(PRINTF,333) IS, ID, IMATLA(ID,IS),IMATDA(ID,IS),
     &                          IMATUA(ID,IS),IMATRA(ID,IS),CAD(ID,IS,1)
333            FORMAT(1X,2I4,4X,4E12.4,E10.2)
            END DO
         END DO
      END IF

      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE SPREDT (SWPDIR     ,AC2        ,CAX       ,
     &                   CAY        ,IDCMIN     ,IDCMAX    ,
     &                   ISSTOP     ,ANYBIN     ,
     &                   XCGRID     ,YCGRID     ,                         41.53
     &                   RDX        ,RDY        ,OBREDF    )              40.00
!
!****************************************************************
!
      USE SWCOMM2                                                         41.53
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!     0. Authors
!
!     40.00, 40.13: Nico Booij
!     40.41: Marcel Zijlema
!     41.53: Marcel Zijlema
!
!     1. UPDATE
!
!        40.00, Aug 98: introduction of obstacle reduction factor to
!                       obtain correct initialisation
!                       argument list changed, swcomm3 added
!        40.13, Aug 01: modification of action densities is skipped
!                       in case of Mode Noupdate
!        40.41, Oct 04: common blocks replaced by modules, include files removed
!        41.53, Oct 14: correction curvilinear grid
!
!     2. PURPOSE
!
!        to estimate the action density depending of the sweep
!        direction during the first iteration of a stationary
!        computation. The reason for this is that AC2 is zero
!        at first iteration and no initialisation is given in
!        case of stationarity (NSTATC=0). Action density should
!        be nonzero because of the computation of the source
!        terms. The estimate is based on solving the equation
!
!            dN       dN
!        CAX -- + CAY -- = 0
!            dx       dy
!
!        in an explicit manner. In the estimate, the transmission
!        through obstacles or reflection at obstacles is taken into
!        account
!
!     3. METHOD
!
!
!          [RDX1*CAX + RDY1*CAY]*N(i-1,j) + [RDX2*CAX + RDY2*CAY]*N(i,j-1)
! N(i,j) = ---------------------------------------------------------------
!                      (RDX1+RDX2) * CAX  +  (RDY1+RDY2) * CAY
!
!     4. PARAMETERLIST
!
!       INTEGERS:
!       ---------
!       IC           Dummy variable: ICode gridpoint:
!                    IC = 1  Top or Bottom gridpoint
!                    IC = 2  Left or Right gridpoint
!                    IC = 3  Central gridpoint
!                    Whether which value IC has, depends of the sweep
!                    If necessary ic can be enlarged by increasing
!                    the array size of ICMAX
!       IX           Counter of gridpoints in x-direction
!       IY           Counter of gridpoints in y-direction
!       IS           Counter of relative frequency band
!       ID           Counter of directional distribution
!       ICMAX        Maximum array size for the points of the molecule
!       MXC          Maximum counter of gridppoints in x-direction
!       MYC          Maximum counter of gridppoints in y-direction
!       MSC          Maximum counter of relative frequency
!       MDC          Maximum counter of directional distribution
!       KSX          Dummy variable to get the right sign in the
!                    numerical difference scheme in X-direction
!                    depending on the sweep direction, KSX = -1 or +1
!       KSY          Dummy variable to get the right sign in the
!                    numerical difference scheme in Y-direction
!                    depending on the sweep direction, KSY = -1 or +1
!       SWPDIR       Sweep direction (..) (identical at the description
!                    of the direction the wind is blowing)
!
!       REALS:
!       ------
!
!       DX           Length of spatial cell in X-direction
!       DY           Length of spatial cell in Y-direction
!       ALEN         Part of side length of an angle side
!       BLEN         Part of side length of an angle side
!       LDIAG        Length of the diagonal of grid cel
!       ALPHA        angle of propagation velocity
!       BETA         angle between DX end DY
!       GAMMA        PI - alpha - beta
!       PI           3,14.......
!       FAC_A        Factor representing the influence of the action-
!                    density depening of the propagation velocity
!       FAC_B        Factor representing the influence of the action-
!                    density depening of the propagation velocity
!
!       REAL arrays:
!       -------------
!
!       AC2    4D    Action density as function of D,S,X,Y at time T
!       CAX    3D    Wave transport velocity in x-direction, function of
!                    (ID,IS,IC)
!       CAY    3D    Wave transport velocity in y-direction, function of
!                    (ID,IS,IC)
!       IDCMIN 1D    frequency dependent counters in case of a current
!       IDCMAX 1D    frequency dependent counters in case of a current
!       ANYBIN 2D    Determines if a bin fall within a sweep
!       XCGRID       coordinates of computational grid in x-direction
!       YCGRID       coordinates of computational grid in y-direction
!
!     5. SUBROUTINES CALLING
!
!        SWOMPU
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. Common blocks used
!
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!   ------------------------------------------------------------
!   For every sweep direction do,
!     For every point in S and D direction in sweep direction do,
!       predict values for action density at new point from values
!       of neighbour gridpoints taking into account spectral propagation
!       direction (with currents !!) and the boundary conditions.
!       --------------------------------------------------------
!       If wave action AC2 is negative, then
!         Give wave action initial value 1.E-10
!     ---------------------------------------------------------
!   End of SPREDT
!   ------------------------------------------------------------
!
!     10. SOURCE
!
!************************************************************************
!
      INTEGER  IS    ,ID    ,
     &         SWPDIR,IDDUM ,ISSTOP                                       40.00
!
      REAL     FAC_A ,FAC_B, WEIG1, WEIG2, TCF1, TCF2, CDEN, CNUM
!
      REAL  :: AC2(MDC,MSC,MCGRD)                                         30.21
!     Changed ICMAX to MICMAX, since MICMAX doesn't vary over gridpoint   40.22
      REAL  :: CAX(MDC,MSC,MICMAX)                                        40.22
      REAL  :: CAY(MDC,MSC,MICMAX)                                        40.22
      REAL  :: RDX(MICMAX),  RDY(MICMAX),                                 40.08 30.21
     &         OBREDF(MDC,MSC,2)                                          40.00
      REAL  :: XCGRID(MXC,MYC), YCGRID(MXC,MYC)                           41.53
!
      INTEGER  IDCMIN(MSC)              ,
     &         IDCMAX(MSC)
!
      LOGICAL  ANYBIN(MDC,MSC)
!
      INTEGER  IDIR, IDCUM, IDMIN, IDMAX, NCURID, NID(4)                  41.53
      REAL     IDX, IDY, CLAT                                             41.53
!
      INTEGER IENT
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'SPREDT')
!
      IF ( OPTG.EQ.3 .AND. CCURV ) THEN
!
!        --- curvilinear grid                                             41.53
!            consider the equation on a rectangular grid                  41.53
!            so that all bins will be filled                              41.53
!
        IDX=1./(XCGRID(IXCGRD(1),IYCGRD(1))-XCGRID(IXCGRD(2),IYCGRD(2)))
        IDY=1./(YCGRID(IXCGRD(1),IYCGRD(1))-YCGRID(IXCGRD(3),IYCGRD(3)))
!
        IF ( KSPHER.GT.0 ) THEN
           CLAT = COS(DEGRAD*(YCGRID(IXCGRD(1),IYCGRD(1))+YOFFS))
           IDX  = IDX / (CLAT * LENDEG)
           IDY  = IDY / LENDEG
        ENDIF
!
        IDCUM = 0
        DO IDIR = 1, 4
           NID(IDIR) = (MDC*IDIR)/4 - IDCUM
           IDCUM     = (MDC*IDIR)/4
        ENDDO
        !
        ! determine loop bounds in spectral space for current sweep
        !
        IDMIN = MDC+1
        IDMAX = 0
        !
        IDIR   = 1
        NCURID = 0
        !
        DO ID = 1, MDC
           !
           IF ( IDIR.EQ.SWPDIR ) THEN
              IDMIN = MIN(ID,IDMIN)
              IDMAX = MAX(ID,IDMAX)
           ENDIF
           NCURID = NCURID + 1
           !
           IF ( NCURID.GE.NID(IDIR) ) THEN
              IDIR   = IDIR + 1
              NCURID = 0
           ENDIF
           !
        ENDDO
!
        DO IS = 1, MSC
          DO ID = IDMIN, IDMAX
!
             IF ( NUMOBS.GT.0 ) THEN
                TCF1 = OBREDF(ID,IS,1)
                TCF2 = OBREDF(ID,IS,2)
             ELSE
                TCF1 = 1.
                TCF2 = 1.
             ENDIF
!
             CDEN = IDX * CAX(ID,IS,1) + IDY * CAY(ID,IS,1)
!
             CNUM = IDX * CAX(ID,IS,2) * TCF1 * AC2(ID,IS,KCGRD(2)) +
     &              IDY * CAY(ID,IS,3) * TCF2 * AC2(ID,IS,KCGRD(3))
!
             IF (ACUPDA) AC2(ID,IS,KCGRD(1)) = CNUM / CDEN
!
          ENDDO
        ENDDO
!
      ELSE
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            IF ( ANYBIN(ID,IS) ) THEN
!
!             *** Computation of weighting coefs WEIG1 AND WEIG2 ***
!
              CDEN = RDX(1) * CAX(ID,IS,1) + RDY(1) * CAY(ID,IS,1)
              CNUM =  (RDX(1) + RDX(2)) * CAX(ID,IS,1)
     &              + (RDY(1) + RDY(2)) * CAY(ID,IS,1)
              WEIG1 = CDEN/CNUM
              WEIG2 = 1. - WEIG1
!
              IF (NUMOBS .GT. 0) THEN
                TCF1 = OBREDF(ID,IS,1)                                    40.00
                TCF2 = OBREDF(ID,IS,2)                                    40.00
              ELSE
                TCF1 = 1.
                TCF2 = 1.
              ENDIF
              FAC_A = TCF1 * WEIG1 * AC2(ID,IS,KCGRD(2))                  40.00
              FAC_B = TCF2 * WEIG2 * AC2(ID,IS,KCGRD(3))                  40.00
!
              IF (ACUPDA)                                                 40.13
     &           AC2(ID,IS,KCGRD(1)) = MAX ( 0. , (FAC_A + FAC_B))        30.21
!
            END IF
          END DO
        END DO
      END IF
!
      IF ( ITEST .GE. 140 .AND. TESTFL ) THEN
        WRITE(PRINTF,6019) KCGRD(1), SWPDIR
 6019   FORMAT(' PREDT : POINT INDX  SWPDIR         :',2I5)
        DO IS = 1, ISSTOP
          DO IDDUM = IDCMIN(IS)-1, IDCMAX(IS)+1
            ID = MOD ( IDDUM - 1 + MDC , MDC ) + 1
            WRITE (PRINTF,6020) IS, ID, AC2(ID,IS,KCGRD(1)),
     &                          AC2(ID,IS,KCGRD(2)),
     &                          AC2(ID,IS,KCGRD(3)),
     &                          ANYBIN(ID,IS)
 6020       FORMAT ('       : IS ID AC2 AC2(2) AC2(3) ANYBIN   :',
     &              2I5,3(E12.4),L4)
          END DO
        END DO
      END IF
!
!     End of the subroutine SPREDT
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE SWAPAR ( DEP, MUDL, KWAVE, CGO, DMW, SPCSIG )
!
!****************************************************************
!
      USE SWCOMM2                                                         40.59
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     30.72: IJsbrand Haagsma
!     30.81: Annette Kieftenburg
!     30.82: IJsbrand Haagsma
!     40.13: Nico Booij
!     40.41: Marcel Zijlema
!     40.59: Erick Rogers
!
!  1. Updates
!
!     20.96, Jan. 96: Computation of CGO etc. taken out of ID loop
!     30.72, Feb. 98: Introduced generic names XCGRID, YCGRID and SPCSIG for SWAN
!     30.81, Dec. 98: Argument list KSCIP1 adjusted
!     30.82, July 99: Corrected argumentlist KSCIP1
!     40.13, Oct. 01: single call to KSCIP1 instead of loop over call
!                     N and ND declared as arrays
!                     loop over IC now inside routine SWAPAR
!     40.41, Aug. 04: CG moved to DSPHER and code optimized
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     40.59, Aug. 07: muddy bottom included
!
!  2. Purpose
!
!     computes the wave parameters K and CGO in the nearby
!     points, depending of the sweep direction.
!     The nearby points are indicated with the index IC (see
!     FUNCTION ICODE(_,_)
!
!  3. Method
!
!     The wave number K(IS,iC) is computed with the dispersion relation:
!
!     S = GRAV K(IS,IC)tanh(K(IS,IC)DEP(IX,IY))
!
!     where S = is logarithmic distributed via LOGSIG
!
!     The group velocity CGO in the case without current is equal to
!
!                    1       K(IS,IC)DEP(IX,IY)          S
!     CGO(IS,IC) = ( - + --------------------------) -----------
!                    2   2 sinh 2K(IS,IC)DEP(IX,IY)  |k(IS,IC)|
!
!  4. Argument variables
!
!     SPCSIG: Relative frequencies in computational domain in sigma-space 30.72
!
      REAL    SPCSIG(MSC)                                                 30.72
!
!        INTEGERS:
!        ---------
!
!        IX          Counter of gridpoints in x-direction
!        IY          Counter of gridpoints in y-direction
!        IS          Counter of relative frequency band
!        ID          Counter of directional distribution
!        ICMAX       Maximum array size for the points of the molecule
!        MXC         Maximum counter of gridppoints in x-direction
!        MYC         Maximum counter of gridppoints in y-direction
!        MSC         Maximum counter of relative frequency
!        MDC         Maximum counter of directional distribution
!
!        REALS:
!        ---------
!
!        GRAV        Gravitational acceleration
!
!        one and more dimensional arrays:
!        ---------------------------------
!
!        CGO       2D    Group velocity as function of X and Y and S in the
!                        direction of wave propagation in absence of currents
!        DEP       2D    Depth as function of X and Y at certain time
!        KWAVE     2D    wavenumber as function of the relative frequency S
!
!     5. SUBROUTINES CALLING
!
!        SWOMPU
!
!     6. SUBROUTINES USED
!
!        ---
!
!     7. Common blocks used
!
!
!     8. REMARKS
!
!     9. STRUCTURE
!
!   -------------------------------------------------------------
!   If depth is negative ( D(IX,IY) <= 0), then,
!     For every point in S and D-direction do,
!       Give wave parameters default values :
!       CGO(IS,IC)  =  0.    ,  {group velocity in absence of a current}
!       K(IS,IC)    = -1.    ,                             {wave number}
!     ---------------------------------------------------------
!   Else
!         Then for every IS do
!           call KSCIP1 to compute wave number and group velocity
!           call KSCIP2 to compute muddy wave number and group velocity
!         ------------------------------------------------------
!   end if
!   ------------------------------------------------------------
!   End of SWAPAR
!   ------------------------------------------------------------
!
!     10. SOURCE
!
!************************************************************************
!
!        IC          Dummy variable: ICode gridpoint:
!                      IC = 1  Top or Bottom gridpoint
!                      IC = 2  Left or Right gridpoint
!                      IC = 3  Central gridpoint
!                    Whether which value IC has, depends of the sweep
!                    If necessary IC can be enlarged by increasing
!                    the array size of ICMAX
      INTEGER      IC    ,IS    ,ID
      REAL      :: N(1:MSC), ND(1:MSC)                                    40.13
!
      REAL         DEP(MCGRD)         ,
     &             MUDL(MCGRD)        ,                                   40.59
     &             KWAVE(MSC,ICMAX)   ,
     &             CGO(MSC,ICMAX)     ,
     &             DMW(MSC,ICMAX)
!
!
      INTEGER, SAVE :: IENT=0
      IF (LTRACE) CALL STRACE (IENT,'SWAPAR')
!
      DO IC = 1, ICMAX                                                    40.13
        INDX   = KCGRD(IC)
        DEPLOC = DEP(INDX)
        IF (VARMUD) THEN
           DM = MUDL(INDX)
        ELSE
           DM = PMUD(1)
        ENDIF
        IF ( DEPLOC .LE. DEPMIN) THEN
!         *** depth is negative ***
          DO 50 IS = 1, MSC
             KWAVE(IS,IC) = -1.                                           40.41
             CGO(IS,IC)   = 0.                                            40.41
             DMW(IS,IC)   = 0.                                            40.59
 50       CONTINUE
        ELSE
!       *** call KSCIP1 to compute KWAVE and CGO ***
          CALL KSCIP1 (MSC, SPCSIG, DEPLOC, KWAVE(1,IC) ,                 40.41
     &                 CGO(1,IC), N, ND)                                  40.41
          IF (IMUD.EQ.1) THEN                                             40.59
!         *** call KSCIP2 to compute KWAVE, CGO and DMW ***
             CALL KSCIP2 (MSC, SPCSIG, DEPLOC, KWAVE(1,IC) ,              40.59
     &                    CGO(1,IC), N, ND, DMW(1,IC), DM)                40.59
          ENDIF
        ENDIF
!
        IF ( TESTFL .AND. IC .EQ. 1 .AND. ITEST.GE. 100 ) THEN
          WRITE(PRINTF,6021) DEP(KCGRD(IC))
 6021     FORMAT(' SWAPAR :                   DEP :',E12.4, /,
     &           '   IS          K           CGO                 :')      40.00
          DO 105 IS = 1, MSC
            WRITE(PRINTF,6019) IS, KWAVE(IS,IC), CGO(IS,IC)               40.41 40.00
 6019       FORMAT(I4, 2E12.4)                                            40.41 40.00
 105      CONTINUE
        END IF
      ENDDO                                                               40.13
!
!     end of subroutine SWAPAR
      RETURN
      END
!
!*******************************************************************
!
      SUBROUTINE ADDDIS (DISSXY     ,LEAKXY     ,
     &                   AC2        ,ANYBIN     ,
     &                   DISC0      ,DISC1      ,
     &                   GENC0      ,GENC1      ,                         40.85
     &                   REDC0      ,REDC1      ,                         40.85
     &                   TRAC0      ,TRAC1      ,                         40.85
     &                   IMATLA     ,IMATUA     ,                         40.85
     &                   IMAT5L     ,IMAT6U     ,                         40.85
     &                   DSXBOT     ,                                     40.67 40.61
     &                   DSXSRF     ,                                     40.67 40.61
     &                   DSXWCP     ,                                     40.67 40.61
     &                   DSXVEG     ,DSXTUR     ,                         40.35 40.67 40.61
     &                   DSXMUD     ,                                     40.67 40.61
     &                   GSXWND     ,GENRXY     ,                         40.85
     &                   RSXQUA     ,RSXTRI     ,                         40.85
     &                   REDSXY     ,                                     40.85
     &                   TSXGEO     ,TSXSPT     ,                         40.85
     &                   TSXSPS     ,TRANXY     ,                         40.85
     &                   LEAKC1     ,RADSXY     ,SPCSIG     )             40.85 30.72
!
!*******************************************************************
!
      USE SWCOMM3                                                         40.41
!
      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     30.72: IJsbrand Haagsma
!     40.61: Marcel Zijlema
!     40.67: Nico Booij
!     40.85: Marcel Zijlema
!
!  1. Updates
!
!     20.53, Aug. 95: New subroutine
!     30.74, Nov. 97: Prepared for version with INCLUDE statements
!     30.72, Feb. 98: Introduced generic names XCGRID, YCGRID and SPCSIG for SWAN
!     40.61, Sep. 06: introduction of all separate dissipation coefficients
!     40.67, Jun. 07: more accurate computation of dissipation terms
!     40.85, Aug. 08: add also propagation, generation and redistribution terms
!                     and radiation stress
!
!  2. Purpose
!
!     Adds propagation, generation, dissipation, redistribution, leak and radiation stress terms
!
!  3. Method
!
!     ---
!
!  4. Argument variables
!
!     SPCSIG: Relative frequencies in computational domain in sigma-space 30.72
!
      REAL    SPCSIG(MSC)                                                 30.72
!
!     IX          Counter of gridpoints in x-direction
!     IY          Counter of gridpoints in y-direction
!     MXC         Maximum counter of gridppoints in x-direction
!     MYC         Maximum counter of gridppoints in y-direction
!     MSC         Maximum counter of relative frequency
!     MDC         Maximum counter of directional distribution
!
!     one and more dimensional arrays:
!     ---------------------------------
!     AC2       4D    Action density as function of D,S,X,Y and T
!
!  7. Common blocks used
!
!
!  8. Subroutines used
!
!     ---
!
!  9. Subroutines calling
!
!     SWOMPU
!
! 11. Remarks
!
!     DISSXY and LEAKXY are dissipation and leak integrated over the
!     spectrum for each point in the computational grid
!     The same holds for DSXBOT, DSXSRF and DSXWCP for bottom friction-,
!     surf- and whitecapping dissipation, respectively
!     DISSC0 and DISSC1 give the dissipation distributed over the
!     spectral space in one point of the computational grid
!     The same holds for DISBOT, DISSRF and DISWCP for bottom friction-,
!     surf- and whitecapping dissipation, respectively
!
! 12. Structure
!
!     -------------------------------------------------------------
!     -------------------------------------------------------------
!
! 13. Source text
!
      INTEGER :: II               ! counter                               40.67
      REAL    :: ADISSIP(1:MDISP)                                         40.67
      REAL    :: AGENERT(1:MGENR)                                         40.85
      REAL    :: AREDIST(1:MREDS)                                         40.85
      REAL    :: ATRANSP(1:MTRNP)                                         40.85
      REAL     DISSXY(MCGRD)    ,LEAKXY(MCGRD)      ,
     &         DSXBOT(MCGRD)      ,                                       40.67 40.61
     &         DSXSRF(MCGRD)      ,                                       40.67 40.61
     &         DSXWCP(MCGRD)      ,                                       40.67 40.61
     &         DSXMUD(MCGRD)      ,                                       40.67 40.61
     &         DSXVEG(MCGRD)      ,                                       40.67 40.61
     &         DSXTUR(MCGRD)      ,                                       40.35
     &         GSXWND(MCGRD)      ,                                       40.85
     &         RSXQUA(MCGRD)      ,                                       40.85
     &         RSXTRI(MCGRD)      ,                                       40.85
     &         TSXGEO(MCGRD)      ,                                       40.85
     &         TSXSPT(MCGRD)      ,                                       40.85
     &         TSXSPS(MCGRD)      ,                                       40.85
     &         GENRXY(MCGRD)      ,REDSXY(MCGRD)    ,TRANXY(MCGRD),       40.85
     &         RADSXY(MCGRD)      ,                                       40.85
     &         LEAKC1(MDC,MSC)  ,AC2(MDC,MSC,MCGRD)                       30.21
      REAL :: DISC0(1:MDC,1:MSC,1:MDISP)       ! dissipation coeff.       40.67
      REAL :: DISC1(1:MDC,1:MSC,1:MDISP)       ! dissipation coeff.       40.67
      REAL :: GENC0(1:MDC,1:MSC,1:MGENR)       ! generation coeff.        40.85
      REAL :: GENC1(1:MDC,1:MSC,1:MGENR)       ! generation coeff.        40.85
      REAL :: REDC0(1:MDC,1:MSC,1:MREDS)       ! redistribution coeff.    40.85
      REAL :: REDC1(1:MDC,1:MSC,1:MREDS)       ! redistribution coeff.    40.85
      REAL :: TRAC0(1:MDC,1:MSC,1:MTRNP)       ! transport coeff.         40.85
      REAL :: TRAC1(1:MDC,1:MSC,1:MTRNP)       ! transport coeff.         40.85
      REAL    IMATLA(MDC,MSC)           ,                                 40.85
     &        IMATUA(MDC,MSC)           ,                                 40.85
     &        IMAT5L(MDC,MSC)           ,                                 40.85
     &        IMAT6U(MDC,MSC)                                             40.85
!
      REAL  ARADSTR, DSDD, SDSDD, S1, ACT1, S2
      REAL  ACT2, S3, ACT3, ACT4, ACT5, ACONTR
      INTEGER ISC, IDC, IDM, IDP
!
      LOGICAL  ANYBIN(MDC,MSC)
      INTEGER, SAVE :: IENT=0
      CALL STRACE (IENT, 'ADDDIS')
!
      ADISSIP(1:MDISP) = 0.                                               40.67
      AGENERT(1:MGENR) = 0.                                               40.85
      AREDIST(1:MREDS) = 0.                                               40.85
      ATRANSP(1:MTRNP) = 0.                                               40.85
      ARADSTR          = 0.                                               40.85
      DO 100 ISC = 1, MSC
        DSDD  = DDIR * FRINTF * SPCSIG(ISC)
        SDSDD = DSDD * SPCSIG(ISC)
        DO 90 IDC = 1, MDC
          IDM = MOD ( IDC - 2 + MDC , MDC ) + 1
          IDP = MOD ( IDC     + MDC , MDC ) + 1
!
          S1   = SPCSIG(ISC)
          ACT1 = AC2(IDC,ISC,KCGRD(1))
          IF (ISC.EQ.1) THEN
             S2   = 0.
             ACT2 = 0.
          ELSE
             S2   = SPCSIG(ISC-1)
             ACT2 = AC2(IDC,ISC-1,KCGRD(1))
          ENDIF
          IF (ISC.EQ.MSC) THEN
             S3   = 0.
             ACT3 = 0.
          ELSE
             S3   = SPCSIG(ISC+1)
             ACT3 = AC2(IDC,ISC+1,KCGRD(1))
          ENDIF
          IF (.NOT.FULCIR .AND. IDC.EQ.1) THEN
             ACT4 = 0.
          ELSE
             ACT4 = AC2(IDM,ISC,KCGRD(1))
          ENDIF
          IF (.NOT.FULCIR .AND. IDC.EQ.MDC) THEN
             ACT5 = 0.
          ELSE
             ACT5 = AC2(IDP,ISC,KCGRD(1))
          ENDIF
!
          IF (ANYBIN(IDC,ISC)) THEN
            LEAKXY(KCGRD(1)) = LEAKXY(KCGRD(1)) + SDSDD*
     &                      LEAKC1(IDC,ISC) * AC2(IDC,ISC,KCGRD(1))
!
!           --- compute for each dissipation term                         40.61
!
            DO II = 1, MDISP                                              40.67
              ACONTR= SDSDD*(DISC0(IDC,ISC,II) + DISC1(IDC,ISC,II)*ACT1)  40.85
              ADISSIP(II) = ADISSIP(II) + ACONTR                          40.85 40.67
              ARADSTR     = ARADSTR     - ACONTR                          40.85
            ENDDO                                                         40.67
!
!           --- compute for each generation term                          40.85
!
            DO II = 1, MGENR                                              40.85
              ACONTR= SDSDD*(GENC0(IDC,ISC,II) + GENC1(IDC,ISC,II)*ACT1)  40.85
              AGENERT(II) = AGENERT(II) + ACONTR                          40.85
              ARADSTR     = ARADSTR     + ACONTR                          40.85
            ENDDO                                                         40.85
!
!           --- compute for each redistribution term                      40.85
!
            DO II = 1, MREDS                                              40.85
              ACONTR= SDSDD*(REDC0(IDC,ISC,II) + REDC1(IDC,ISC,II)*ACT1)  40.85
              AREDIST(II) = AREDIST(II) + ABS(ACONTR)                     40.85
              ARADSTR     = ARADSTR     + ACONTR                          40.85
            ENDDO                                                         40.85
!
!           --- compute for each propagation term
!
            ACONTR = SDSDD* (TRAC0(IDC,ISC,1) + TRAC1(IDC,ISC,1)*ACT1)    40.85
            ATRANSP(1) = ATRANSP(1) + ABS(ACONTR)                         40.85
            ARADSTR    = ARADSTR    - ACONTR                              40.85
!
            ACONTR = SDSDD* (TRAC0(IDC,ISC,2)      +                      40.85
     &                       TRAC1(IDC,ISC,2)*ACT1 +                      40.85
     &                       IMATLA(IDC,ISC) *ACT4 +                      40.85
     &                       IMATUA(IDC,ISC) *ACT5 )                      40.85
            ATRANSP(2) = ATRANSP(2) + ABS(ACONTR)                         40.85
            ARADSTR    = ARADSTR    - ACONTR                              40.85
!
            ACONTR = DSDD * (TRAC0(IDC,ISC,3)           +                 40.85
     &                       TRAC1(IDC,ISC,3)* S1 *ACT1 +                 40.85
     &                       IMAT5L(IDC,ISC) * S2 *ACT2 +                 40.85
     &                       IMAT6U(IDC,ISC) * S3 *ACT3 )                 40.85
            ATRANSP(3) = ATRANSP(3) + ABS(ACONTR)                         40.85
            ARADSTR    = ARADSTR    - ACONTR                              40.85
!
            ARADSTR    = ABS(ARADSTR)                                     40.85
          ENDIF
  90    CONTINUE
 100  CONTINUE
!
      DSXWCP(KCGRD(1)) = DSXWCP(KCGRD(1)) + ADISSIP(1)     ! whitecapping         40.67
      DSXSRF(KCGRD(1)) = DSXSRF(KCGRD(1)) + ADISSIP(2)     ! surf break           40.67
      DSXBOT(KCGRD(1)) = DSXBOT(KCGRD(1)) + ADISSIP(3)     ! bottom fric          40.67
      DSXVEG(KCGRD(1)) = DSXVEG(KCGRD(1)) + ADISSIP(5)     ! vegetation           40.67
      DSXTUR(KCGRD(1)) = DSXTUR(KCGRD(1)) + ADISSIP(6)     ! turbulence           40.35
      DSXMUD(KCGRD(1)) = DSXMUD(KCGRD(1)) + ADISSIP(7)     ! mud dissip           40.67
      DISSXY(KCGRD(1)) = DISSXY(KCGRD(1)) + SUM(ADISSIP)   ! total dissip         40.67
!
      GSXWND(KCGRD(1)) = GSXWND(KCGRD(1)) + AGENERT(1)     ! wind input           40.85
      GENRXY(KCGRD(1)) = GENRXY(KCGRD(1)) + SUM(AGENERT)   ! total generation     40.85
!
      RSXQUA(KCGRD(1)) = RSXQUA(KCGRD(1)) + AREDIST(1)     ! quadruplets          40.85
      RSXTRI(KCGRD(1)) = RSXTRI(KCGRD(1)) + AREDIST(2)     ! triads               40.85
      REDSXY(KCGRD(1)) = REDSXY(KCGRD(1)) + SUM(AREDIST)   ! total redistribution 40.85
!
      TSXGEO(KCGRD(1)) = TSXGEO(KCGRD(1)) + ATRANSP(1)     ! xy-propagation       40.85
      TSXSPT(KCGRD(1)) = TSXSPT(KCGRD(1)) + ATRANSP(2)     ! theta-propagation    40.85
      TSXSPS(KCGRD(1)) = TSXSPS(KCGRD(1)) + ATRANSP(3)     ! sigma-propagation    40.85
      TRANXY(KCGRD(1)) = TRANXY(KCGRD(1)) + SUM(ATRANSP)   ! total propagation    40.85
!
!       energy transfer between waves and currents due to radiation stress, see page 439 of
!       the ICCE paper of Holthuijsen, L.H., Zijlema, M. and Van der Ham, P.J. (2009)
!       Wave physics in a tidal inlet, in: J.M. Smith (Ed.), Proc. 31st Int. Conf. on Coast. Engng.
!       ASCE, World Scientific Publishing, Singapore, 437-448
!
      RADSXY(KCGRD(1)) = RADSXY(KCGRD(1)) + ARADSTR                       40.85
!
      IMATLA = 0.
      IMATUA = 0.
      IMAT5L = 0.
      IMAT6U = 0.
!
      RETURN
      END
!
!****************************************************************
!
      SUBROUTINE SWFLXD (CAD   , IMATLA, IMATDA, IMATUA, IMATRA,
     &                   AC2   , DD    , ANYBIN, LEAKC1, IDCMIN,
     &                   IDCMAX, ISSTOP)
!
!****************************************************************
!
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
!
      IMPLICIT NONE
!
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering and Geosciences              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmer: Marcel Zijlema                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     40.23: Marcel Zijlema
!     40.41: Marcel Zijlema
!
!  1. Updates
!
!     40.23, Nov. 02: New subroutine
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!
!  2. Purpose
!
!     computation of @[CAD AC2]/@D by means of flux-limiting
!
!  3. Method
!
!     Discretization is based on flux-limiting and is regarded
!     as the sum of first order upwind scheme and anti-diffusive
!     parts containing the PL-kappa slope limiter
!
!  4. Argument variables
!
!     AC2         action density
!     ANYBIN      logical: indicate whether current bin is selected
!     CAD         wave transport velocity in D-direction
!     DD          width of spectral direction band
!     IDCMAX      frequency dependent counter
!     IDCMIN      frequency dependent counter
!     IMATDA      coefficients of diagonal of matrix
!     IMATLA      coefficients of lower diagonal of matrix
!     IMATRA      coefficients of right hand side
!     IMATUA      coefficients of upper diagonal of matrix
!     ISSTOP      maximum frequency counter in a sweep
!     LEAKC1      leak coefficient
!
      INTEGER ISSTOP
      INTEGER IDCMIN(MSC), IDCMAX(MSC)
      REAL    DD
      REAL    AC2(MDC,MSC,MCGRD),
     &        CAD(MDC,MSC,ICMAX),
     &        IMATLA(MDC,MSC)   ,
     &        IMATDA(MDC,MSC)   ,
     &        IMATUA(MDC,MSC)   ,
     &        IMATRA(MDC,MSC)   ,
     &        LEAKC1(MDC,MSC)
      LOGICAL ANYBIN(MDC,MSC)
!
!  6. Local variables
!
!     ACM   :     lower action
!     ACP   :     upper action
!     ACT0  :     action in centroid (=ID)
!     ACT1  :     action in lower node (=ID-1)
!     ACT2  :     action in upper node (=ID+1)
!     ACT3  :     action in 2 points away from centre (=ID+2)
!     BINM  :     indicate whether lower bin is selected
!     BINP  :     indicate whether upper bin is selected
!     CADM  :     lower wave transport velocity
!     CADP  :     upper wave transport velocity
!     CAN   :     negative wave transport velocity
!     CAP   :     positive wave transport velocity
!     CAV   :     averaged wave transport velocity; may be
!                 regarded as flux velocity
!     DDI   :     inverse of width of spectral direction band
!     DFCOR :     auxiliary real containing anti-diffusive parts
!                 to be regarded as defect correction
!     FACT  :     auxiliary factor
!     ID    :     counter
!     IDDUM :     loop counter
!     IDM   :     index of point ID-1
!     IDP   :     index of point ID+1
!     IENT  :     number of entries
!     IS    :     loop counter
!     RAN   :     ratio of consecutive gradients i.c. negative velocity
!     RAP   :     ratio of consecutive gradients i.c. positive velocity
!     XKAP  :     control parameter meant for the kappa-scheme
!     XLIMN :     flux-limiter i.c. negative velocity
!     XLIMP :     flux-limiter i.c. positive velocity
!
      INTEGER IENT, ID, IDM, IDP, IDDUM, IS
      REAL    ACM, ACP, ACT0, ACT1, ACT2, ACT3, CADM, CADP,
     &        CAN, CAP, CAV, DDI, DFCOR, FACT, RAN, RAP, XKAP,
     &        XLIMN, XLIMP
      LOGICAL BINM, BINP
!
!  8. Subroutines used
!
!     STRACE           Tracing routine for debugging
!
!  9. Subroutines calling
!
!     ACTION (in SWANCOM1)
!
! 12. Structure
!
!     For every S and D-direction in direction of sweep do
!
!        Compute the derivative in D-direction and
!        store the results of this calculation in the
!        arrays IMATDA, IMATLA, IMATUA and IMATRA
!
! 13. Source text
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'SWFLXD')

      DDI  = 1./DD
      XKAP = PNUMS(6)

      DO 20 IS = 1, ISSTOP

         DO 10 IDDUM = IDCMIN(IS), IDCMAX(IS)
            ID = MOD (IDDUM-1+MDC, MDC) + 1

            IF ( ANYBIN(ID,IS) ) THEN

               IF ( IDDUM.EQ.IDCMIN(IS) ) THEN

                  IF ( FULCIR .OR. ID.GT.1 ) THEN
                     IDM  = MOD (IDDUM-2+MDC, MDC) + 1
                     CADM = CAD(IDM,IS,1)
                     BINM = ANYBIN(IDM,IS)
                     IF (.NOT.BINM) ACM = AC2(IDM,IS,KCGRD(1))
                  ELSE
                     IDM  = 0
                     CADM = CAD(ID,IS,1)
                     BINM = .FALSE.
                     ACM  = 0.
                  END IF

                  CAV = 0.5*(CAD(ID,IS,1) + CADM)
                  CAP = 0.5*(CAV + ABS(CAV))
                  CAN = 0.5*(CAV - ABS(CAV))

                  IF ( FULCIR .OR. ID.GT.1 ) THEN
                     ACT0 = AC2(MOD(IDDUM-2+MDC,MDC)+1,IS,KCGRD(1))
                  ELSE
                     ACT0 = 0.
                  END IF
                  IF ( FULCIR .OR. ID.GT.2 ) THEN
                     ACT1 = AC2(MOD(IDDUM-3+MDC,MDC)+1,IS,KCGRD(1))
                  ELSE
                     ACT1 = 0.
                  END IF
                  ACT2 = AC2(ID,IS,KCGRD(1))
                  IF ( FULCIR .OR. ID.LT.MDC ) THEN
                     ACT3 = AC2(MOD(IDDUM+MDC,MDC)+1,IS,KCGRD(1))
                  ELSE
                     ACT3 = 0.
                  END IF

                  RAP = (ACT2-ACT0+1.E-12)/(ACT0-ACT1+1.E-12)
                  RAN = (ACT2-ACT0+1.E-12)/(ACT3-ACT2+1.E-12)

                  FACT  = MIN( 2., 0.5*(1.+XKAP)*RAP + 0.5*(1.-XKAP) )
                  XLIMP = MAX( 0., MIN(2.*RAP,FACT) )

                  FACT  = MIN( 2., 0.5*(1.+XKAP)*RAN + 0.5*(1.-XKAP) )
                  XLIMN = MAX( 0., MIN(2.*RAN,FACT) )

                  DFCOR = 0.5*(CAP*XLIMP*(ACT0 - ACT1) -
     &                         CAN*XLIMN*(ACT3 - ACT2))

                  IF ( .NOT.BINM ) THEN
                     IMATDA(ID,IS) = IMATDA(ID,IS) - DDI * CAN
                     IMATRA(ID,IS) = IMATRA(ID,IS) + DDI * CAP * ACM
                     IF (IDM.NE.0)
     &                   IMATRA(ID,IS) = IMATRA(ID,IS) + DDI * DFCOR
                  END IF

                  IF ( IDM.EQ.0 ) LEAKC1(ID,IS) = -CAN

               END IF

               IF ( FULCIR .OR. ID.LT.MDC ) THEN
                  IDP  = MOD (IDDUM+MDC, MDC) + 1
                  CADP = CAD(IDP,IS,1)
                  BINP = ANYBIN(IDP,IS)
                  IF (.NOT.BINP) ACP = AC2(IDP,IS,KCGRD(1))
               ELSE
                  IDP  = 0
                  CADP = CAD(ID,IS,1)
                  BINP = .FALSE.
                  ACP  = 0.
               END IF

               CAV = 0.5*(CAD(ID,IS,1) + CADP)
               CAP = 0.5*(CAV + ABS(CAV))
               CAN = 0.5*(CAV - ABS(CAV))

               ACT0 = AC2(ID,IS,KCGRD(1))
               IF ( FULCIR .OR. ID.GT.1 ) THEN
                  ACT1 = AC2(MOD(IDDUM-2+MDC,MDC)+1,IS,KCGRD(1))
               ELSE
                  ACT1 = 0.
               END IF
               IF ( FULCIR .OR. ID.LT.MDC ) THEN
                  ACT2 = AC2(MOD(IDDUM+MDC,MDC)+1,IS,KCGRD(1))
               ELSE
                  ACT2 = 0.
               END IF
               IF ( FULCIR .OR. ID.LT.MDC-1 ) THEN
                  ACT3 = AC2(MOD(IDDUM+1+MDC,MDC)+1,IS,KCGRD(1))
               ELSE
                  ACT3 = 0.
               END IF

               RAP = (ACT2-ACT0+1.E-12)/(ACT0-ACT1+1.E-12)
               RAN = (ACT2-ACT0+1.E-12)/(ACT3-ACT2+1.E-12)

               FACT  = MIN( 2., 0.5*(1.+XKAP)*RAP + 0.5*(1.-XKAP) )
               XLIMP = MAX( 0., MIN(2.*RAP,FACT) )

               FACT  = MIN( 2., 0.5*(1.+XKAP)*RAN + 0.5*(1.-XKAP) )
               XLIMN = MAX( 0., MIN(2.*RAN,FACT) )

               DFCOR = 0.5*(CAP*XLIMP*(ACT0-ACT1)-CAN*XLIMN*(ACT3-ACT2))

               IF ( BINP ) THEN
                  IMATDA(ID ,IS) = IMATDA(ID ,IS) + DDI * CAP
                  IMATUA(ID ,IS) = IMATUA(ID ,IS) + DDI * CAN
                  IMATDA(IDP,IS) = IMATDA(IDP,IS) - DDI * CAN
                  IMATLA(IDP,IS) = IMATLA(IDP,IS) - DDI * CAP
                  IMATRA(ID ,IS) = IMATRA(ID ,IS) - DDI * DFCOR
                  IMATRA(IDP,IS) = IMATRA(IDP,IS) + DDI * DFCOR
               ELSE
                  IMATDA(ID,IS) = IMATDA(ID,IS) + DDI * CAP
                  IMATRA(ID,IS) = IMATRA(ID,IS) - DDI * CAN * ACP
                  IF (IDP.NE.0)
     &                IMATRA(ID,IS) = IMATRA(ID,IS) - DDI * DFCOR
               END IF

               IF ( IDP.EQ.0 ) LEAKC1(ID,IS) = CAP

            END IF

 10      CONTINUE
 20   CONTINUE
!
!     --- test output
!
      IF ( TESTFL .AND. ITEST.GE.80 ) THEN
         WRITE(PRINTF,111) KCGRD(1), ISSTOP
111      FORMAT(' SWFLXD: POINT  ISSTOP  :',2I5)
         WRITE(PRINTF,222) PNUMS(6)
222      FORMAT(' SWFLXD: CDD            :',E12.4)
         WRITE(PRINTF,*)
         WRITE(PRINTF,*) ' matrix coefficients in SWFLXD'
         WRITE(PRINTF,*)
         WRITE(PRINTF,*)
     &'   IS ID      IMATLA      IMATDA      IMATUA      IMATRA     CAD'
         DO IS = 1, ISSTOP
            DO IDDUM = IDCMIN(IS), IDCMAX(IS)
               ID = MOD (IDDUM-1+MDC, MDC) + 1
               WRITE(PRINTF,333) IS, ID, IMATLA(ID,IS),IMATDA(ID,IS),
     &                          IMATUA(ID,IS),IMATRA(ID,IS),CAD(ID,IS,1)
333            FORMAT(1X,2I4,4X,4E12.4,E10.2)
            END DO
         END DO
      END IF

      RETURN
      END
!****************************************************************
!
      SUBROUTINE DIFPAR( AC2   , SPCSIG, KGRPNT, DEP2  ,
     &                   CROSS , XCGRID, YCGRID, XYTST )
!
!****************************************************************
!
      USE SWCOMM2                                                         40.41
      USE SWCOMM3                                                         40.41
      USE SWCOMM4                                                         40.41
      USE OCPCOMM4                                                        40.41
      USE M_DIFFR
      USE M_PARALL

      IMPLICIT NONE
!
!
!   --|-----------------------------------------------------------|--
!     | Delft University of Technology                            |
!     | Faculty of Civil Engineering                              |
!     | Environmental Fluid Mechanics Section                     |
!     | P.O. Box 5048, 2600 GA  Delft, The Netherlands            |
!     |                                                           |
!     | Programmers: The SWAN team                                |
!   --|-----------------------------------------------------------|--
!
!
!     SWAN (Simulating WAves Nearshore); a third generation wave model
!     Copyright (C) 1993-2016  Delft University of Technology
!
!     This program is free software; you can redistribute it and/or
!     modify it under the terms of the GNU General Public License as
!     published by the Free Software Foundation; either version 2 of
!     the License, or (at your option) any later version.
!
!     This program is distributed in the hope that it will be useful,
!     but WITHOUT ANY WARRANTY; without even the implied warranty of
!     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!     GNU General Public License for more details.
!
!     A copy of the GNU General Public License is available at
!     http://www.gnu.org/copyleft/gpl.html#SEC3
!     or by writing to the Free Software Foundation, Inc.,
!     59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
!
!
!  0. Authors
!
!     40.21: Agnieszka Herman, Nico Booij
!     40.41: Marcel Zijlema
!     40.68: Marcel Zijlema
!
!  1. Updates
!
!     40.21, Aug. 01: New subroutine
!     40.41, Mar. 04: parallelization of diffraction
!     40.41, Oct. 04: common blocks replaced by modules, include files removed
!     40.68, Aug. 07: extension to spherical coordinates
!
!  2. Purpose
!
!     Computes diffraction parameter and its derivatives
!
!  3. Method
!
!     Parameters governing smoothing of the energy field.
!
!     Effectively, E(i,j) = (1-4*alpha) * E(i,j) +
!                           alpha * (E(i-1,j)+E(i+1,j)+E(i,j-1)+E(i,j+1))
!
!     Parameters governing numerical computation of diffraction
!     coefficient and its spatial derivatives:
!
!     DIFPARAM=SQRT(1+delta)
!
!     Near land and obstacles derivatives are assumed to be zero
!
!  4. Argument variables
!
!     AC2         action density
!     CROSS       integer array indicating obstacle crossing
!                 (0=no, 1=yes)
!     DEP2        current total depth
!     KGRPNT      indirect address for grid points
!     SPCSIG      relative frequencies in sigma-space
!     XCGRID      x-coordinate of computational grid
!     YCGRID      y-coordinate of computational grid
!     XYTST       grid indices of test points
!
      INTEGER, INTENT(IN)    :: KGRPNT(MXC,MYC)
      REAL   , INTENT(IN)    :: SPCSIG(MSC)
      REAL   , INTENT(INOUT) :: AC2(MDC,MSC,MCGRD)
      REAL   , INTENT(IN)    :: DEP2(MCGRD)
      REAL   , INTENT(IN)    :: CROSS(2,MCGRD)
      REAL   , INTENT(IN)    :: XCGRID(MXC,MYC)
      REAL   , INTENT(IN)    :: YCGRID(MXC,MYC)
      INTEGER, INTENT(IN)    :: XYTST(*)
!
!  6. Local variables
!
!     IENT  :     number of entries
!     IX1   :     lower index in x-direction
!     IX2   :     upper index in x-direction
!     IY1   :     lower index in y-direction
!     IY2   :     upper index in y-direction
!     NOOBST:     indicates obstacles in the model (FALSE) or not (TRUE)
!
      INTEGER           :: IS, ISM, IENT
      INTEGER           :: IX, IY, IND, INDL, INDR, INDB, INDT
      INTEGER           :: IX1, IX2, IY1, IY2, IXB, IXE, IYB, IYE
      INTEGER           :: MXCL, MYCL, IXX, IYY, IXXL, IXXR, IYYB, IYYT
      REAL              :: CETAIL, PPTAIL, CKTAIL
      REAL              :: ETOT, EKTOTL, ECGTOT, TMP
      REAL              :: EAD, TMP_X, TMP_Y, CSLAT
      REAL              :: DXLOC, DYLOC
      REAL              :: KLOC(1:MSC), CGLOC(1:MSC), N(1:MSC),
     &                     ND(1:MSC)
      REAL, ALLOCATABLE :: EN(:), LAPE(:), DENOM(:), K(:), CG(:)
      REAL, ALLOCATABLE :: ENTMP(:,:)
      LOGICAL           :: NOOBST
!
!  8. Subroutines used
!
!     EQREAL           logical function, true if arguments are equal
!     KSCIP1           calculates wave number and group velocity
!     STPNOW           Logical indicating whether program must
!                      terminated or not
!     STRACE           Tracing routine for debugging
!     SWEXCHG          exchanges some data at subdomain boundaries
!
      LOGICAL EQREAL, STPNOW
!
!  9. Subroutines calling
!
!     ---
!
! 10. Error messages
!
!     ---
!
! 11. Remarks
!
!     ---
!
! 12. Structure
!
!     ---
!
! 13. Source text
!
      SAVE IENT
      DATA IENT/0/
      IF (LTRACE) CALL STRACE (IENT,'DIFPAR')

!     --- allocate arrays
      ALLOCATE (EN(1:MCGRD), LAPE(1:MCGRD), DENOM(1:MCGRD))
      ALLOCATE (K(1:MCGRD), CG(1:MCGRD))

!     --- determine bounds of own subdomain

      IX1 = 1
      IF (.NOT.LMXF) IX1 = 1+IHALOX                                       40.41
      IX2 = MXC
      IF (.NOT.LMXL) IX2 = MXC-IHALOX                                     40.41
      IY1 = 1
      IF (.NOT.LMYF) IY1 = 1+IHALOY                                       40.41
      IY2 = MYC
      IF (.NOT.LMYL) IY2 = MYC-IHALOY                                     40.41
      MXCL = IX2 - IX1 + 1                                                40.41
      MYCL = IY2 - IY1 + 1                                                40.41
      ALLOCATE (ENTMP(0:MXCL+1,0:MYCL+1))                                 40.41

      K (1) = 10.
      CG(1) = 0.
      EN(1) = 0.

!     --- compute total energy and mean wave number
!         in each computational grid point

      DO IND = 2, MCGRD
         IF (DEP2(IND).GE.DEPMIN) THEN
!           --- compute Cg and wave number for all spectral frequencies
            CALL KSCIP1( MSC, SPCSIG, DEP2(IND), KLOC, CGLOC, N, ND )
            ETOT   = 0.
            EKTOTL = 0.
            ECGTOT = 0.
            DO IS = 1, MSC
!              --- integrate energy density over directions
               EAD = SUM(AC2(:,IS,IND)) * DDIR * SPCSIG(IS)**2
               ETOT   = ETOT   + EAD
               EKTOTL = EKTOTL + KLOC (IS) * EAD
               ECGTOT = ECGTOT + CGLOC(IS) * EAD
            END DO
            ETOT   = FRINTF * ETOT
            EKTOTL = FRINTF * EKTOTL
            ECGTOT = FRINTF * ECGTOT
            IF (MSC .GT. 3) THEN
               PPTAIL = PWTAIL(1) - 1.
               CETAIL = 1. / (PPTAIL * (1. + PPTAIL * (FRINTH-1.)))
               PPTAIL = PWTAIL(1) - 1. - 2.
               CKTAIL = 1. / (PPTAIL * (1. + PPTAIL * (FRINTH-1.)))
               ETOT   = ETOT   + CETAIL * EAD
               EKTOTL = EKTOTL + CKTAIL * EAD
               ECGTOT = ECGTOT + CKTAIL * EAD
            END IF
            IF (ETOT.LE.0.) THEN
               K (IND) = 10.
               CG(IND) = 0.
               EN(IND) = 0.
            ELSE
               K (IND) = EKTOTL / ETOT
               CG(IND) = ECGTOT / ETOT
               EN(IND) = MAX(ETOT,1.E-8)
            END IF
         ELSE
            K (IND) = 10.
            CG(IND) = 0.
            EN(IND) = 0.
         END IF
      END DO

!     --- apply a smoothing filter to the energy field

      DO ISM = 1, INT(PDIFFR(2))                                          40.41
         IXB = MAX(IX1-1,1  )                                             40.41
         IXE = MIN(IX2+1,MXC)                                             40.41
         IYB = MAX(IY1-1,1  )                                             40.41
         IYE = MIN(IY2+1,MYC)                                             40.41
         ENTMP = 0.                                                       40.41
         DO IX= IXB, IXE                                                  40.41
            DO IY = IYB, IYE                                              40.41
               ENTMP(IX-IX1+1,IY-IY1+1) = EN(KGRPNT(IX,IY))               40.41
            END DO                                                        40.41
         END DO                                                           40.41
         DO IX= 1, MXCL                                                   40.41
            DO IY = 1, MYCL                                               40.41
               IXX  = IX + IX1 - 1                                        40.41
               IYY  = IY + IY1 - 1                                        40.41
               IXXL = MAX(IXX-1,1  )                                      40.41
               IXXR = MIN(IXX+1,MXC)                                      40.41
               IYYB = MAX(IYY-1,1  )                                      40.41
               IYYT = MIN(IYY+1,MYC)                                      40.41
               IND  = KGRPNT(IXX ,IYY )                                   40.41
               INDL = KGRPNT(IXXL,IYY )                                   40.41
               INDR = KGRPNT(IXXR,IYY )                                   40.41
               INDB = KGRPNT(IXX ,IYYB)                                   40.41
               INDT = KGRPNT(IXX ,IYYT)                                   40.41
               TMP = PDIFFR(1)                                            40.41
               IF (NUMOBS.EQ.0) THEN                                      40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE IF (CROSS(1,IND).EQ.0) THEN                           40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE                                                       40.41
                  NOOBST=.FALSE.                                          40.41
               END IF                                                     40.41
               IF (NOOBST                                                 40.41
     &             .AND. DEP2(IND ) .GT. DEPMIN                           40.41
     &             .AND. DEP2(INDL) .GT. DEPMIN                           40.41
     &             .AND. (.NOT.LMXF.OR.IX.NE.1)                           40.41
     &             .AND. (.NOT.LMYF.OR.IY.NE.1) ) THEN                    40.41
                  EN(IND) = ENTMP(IX,IY) -                                40.41
     &                                TMP*(ENTMP(IX,IY)-ENTMP(IX-1,IY))   40.41
               END IF                                                     40.41
               IF (NUMOBS.EQ.0) THEN                                      40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE IF (CROSS(1,INDR).EQ.0) THEN                          40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE                                                       40.41
                  NOOBST=.FALSE.                                          40.41
               END IF                                                     40.41
               IF (NOOBST                                                 40.41
     &             .AND. DEP2(IND ) .GT. DEPMIN                           40.41
     &             .AND. DEP2(INDR) .GT. DEPMIN                           40.41
     &             .AND. (.NOT.LMXL.OR.IX.NE.MXCL)                        40.41
     &             .AND. (.NOT.LMYF.OR.IY.NE.1   ) ) THEN                 40.41
                  EN(IND) = EN(IND) - TMP*(ENTMP(IX,IY)-ENTMP(IX+1,IY))   40.41
               END IF                                                     40.41
               IF (NUMOBS.EQ.0) THEN                                      40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE IF (CROSS(2,IND).EQ.0) THEN                           40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE                                                       40.41
                  NOOBST=.FALSE.                                          40.41
               END IF                                                     40.41
               IF (NOOBST                                                 40.41
     &             .AND. DEP2(IND ) .GT. DEPMIN                           40.41
     &             .AND. DEP2(INDB) .GT. DEPMIN                           40.41
     &             .AND. (.NOT.LMYF.OR.IY.NE.1)                           40.41
     &             .AND. (.NOT.LMXF.OR.IX.NE.1) ) THEN                    40.41
                  EN(IND) = EN(IND) - TMP*(ENTMP(IX,IY)-ENTMP(IX,IY-1))   40.41
               END IF                                                     40.41
               IF (NUMOBS.EQ.0) THEN                                      40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE IF (CROSS(2,INDT).EQ.0) THEN                          40.41
                  NOOBST=.TRUE.                                           40.41
               ELSE                                                       40.41
                  NOOBST=.FALSE.                                          40.41
               END IF                                                     40.41
               IF (NOOBST                                                 40.41
     &             .AND. DEP2(IND ) .GT. DEPMIN                           40.41
     &             .AND. DEP2(INDT) .GT. DEPMIN                           40.41
     &             .AND. (.NOT.LMYL.OR.IY.NE.MYCL)                        40.41
     &             .AND. (.NOT.LMXF.OR.IX.NE.1   ) ) THEN                 40.41
                  EN(IND) = EN(IND) - TMP*(ENTMP(IX,IY)-ENTMP(IX,IY+1))   40.41
               END IF                                                     40.41
            END DO                                                        40.41
         END DO                                                           40.41
         CALL SWEXCHG(EN,KGRPNT)                                          40.41
!JAC         CALL SWEXCHG(EN,0,KGRPNT)                                        40.41
         IF (STPNOW()) RETURN                                             40.41
      END DO                                                              40.41

!     --- transform energy density into wave amplitude
      EN(1:MCGRD) = SQRT(MAX(EN(1:MCGRD),0.))

!     --- compute Laplacian of SQRT(energy) in each computational grid point

!     --- initially, set all values to zero
      DENOM(1:MCGRD) = 0.
      LAPE (1:MCGRD) = 0.
      DIFPARDX(1:MCGRD) = 0.
      DIFPARDY(1:MCGRD) = 0.

!     --- loop over all X-connections
      DO IX = MAX(IX1,2), MIN(IX2+1,MXC)                                  40.41
         DO IY = IY1, IY2                                                 40.41
            IND  = KGRPNT(IX  ,IY)
            INDL = KGRPNT(IX-1,IY)
            IF (NUMOBS.EQ.0) THEN                                         40.41
               NOOBST=.TRUE.                                              40.41
            ELSE IF (CROSS(1,IND).EQ.0) THEN                              40.41
               NOOBST=.TRUE.                                              40.41
            ELSE                                                          40.41
               NOOBST=.FALSE.                                             40.41
            END IF                                                        40.41
            IF (NOOBST                                                    40.41
     &          .AND.DEP2(IND ).GT.DEPMIN
     &          .AND.DEP2(INDL).GT.DEPMIN) THEN
               IF ( OPTG.EQ.1 ) THEN
                  DXLOC = DX
                  DYLOC = DY
               ELSE IF ( OPTG.EQ.3 ) THEN                                 40.80
                  DXLOC = XCGRID(IX,IY) - XCGRID(IX-1,IY)
                  IF (LMYF .AND. IY.EQ.1) THEN
                     DYLOC = YCGRID(IX,IY+1) - YCGRID(IX,IY)
                  ELSE IF (LMYL .AND. IY.EQ.MYC) THEN
                     DYLOC = YCGRID(IX,IY) - YCGRID(IX,IY-1)
                  ELSE
                     DYLOC = 0.5*( YCGRID(IX,IY+1) -
     &                             YCGRID(IX,IY-1) )
                  END IF
               END IF
               IF ( KSPHER.GT.0 ) THEN                                    40.68
                  CSLAT = COS(DEGRAD*(YOFFS+YCGRID(IX,IY)))               40.68
                  DXLOC = DXLOC * LENDEG * CSLAT                          40.68
                  DYLOC = DYLOC * LENDEG                                  40.68
               ENDIF                                                      40.68
               DXLOC = ABS(DXLOC)
               DYLOC = ABS(DYLOC)
               IF (EQREAL(DXLOC,0.)) DXLOC = 0.01
               IF (EQREAL(DYLOC,0.)) DYLOC = 0.01
               TMP = 0.5*(CG(INDL)/K(INDL)+CG(IND)/K(IND)) *
     &                   DYLOC * (EN(IND)-EN(INDL)) / DXLOC
               EAD = DXLOC * DYLOC * EN(IND)*CG(IND)*K(IND)
               LAPE (INDL) = LAPE (INDL) + TMP
               LAPE (IND ) = LAPE (IND ) - TMP
               DENOM(IND ) = DENOM(IND ) + EAD
            END IF
         END DO
      END DO

!     --- loop over all Y-connections
      DO IX = IX1, IX2                                                    40.41
         DO IY = MAX(IY1,2), MIN(IY2+1,MYC)                               40.41
            IND  = KGRPNT(IX,IY  )
            INDB = KGRPNT(IX,IY-1)
            IF (NUMOBS.EQ.0) THEN                                         40.41
               NOOBST=.TRUE.                                              40.41
            ELSE IF (CROSS(2,IND).EQ.0) THEN                              40.41
               NOOBST=.TRUE.                                              40.41
            ELSE                                                          40.41
               NOOBST=.FALSE.                                             40.41
            END IF                                                        40.41
            IF (NOOBST                                                    40.41
     &          .AND.DEP2(IND ).GT.DEPMIN
     &          .AND.DEP2(INDB).GT.DEPMIN) THEN
               IF ( OPTG.EQ.1 ) THEN
                  DXLOC = DX
                  DYLOC = DY
               ELSE IF ( OPTG.EQ.3 ) THEN                                 40.80
                  DYLOC = YCGRID(IX,IY) - YCGRID(IX,IY-1)
                  IF (LMXF .AND. IX.EQ.1) THEN
                     DXLOC = XCGRID(IX+1,IY) - XCGRID(IX,IY)
                  ELSE IF (LMXL .AND. IX.EQ.MXC) THEN
                     DXLOC = XCGRID(IX,IY) - XCGRID(IX-1,IY)
                  ELSE
                     DXLOC = 0.5*( XCGRID(IX+1,IY) -
     &                             XCGRID(IX-1,IY) )
                  END IF
               END IF
               IF ( KSPHER.GT.0 ) THEN                                    40.68
                  CSLAT = COS(DEGRAD*(YOFFS+YCGRID(IX,IY)))               40.68
                  DXLOC = DXLOC * LENDEG * CSLAT                          40.68
                  DYLOC = DYLOC * LENDEG                                  40.68
               ENDIF                                                      40.68
               DXLOC = ABS(DXLOC)
               DYLOC = ABS(DYLOC)
               IF (EQREAL(DXLOC,0.)) DXLOC = 0.01
               IF (EQREAL(DYLOC,0.)) DYLOC = 0.01
               TMP = 0.5*(CG(INDB)/K(INDB)+CG(IND)/K(IND)) *
     &                   DXLOC * (EN(IND)-EN(INDB)) / DYLOC
               EAD = DXLOC * DYLOC * EN(IND)*CG(IND)*K(IND)
               LAPE (INDB) = LAPE (INDB) + TMP
               LAPE (IND ) = LAPE (IND ) - TMP
               DENOM(IND ) = DENOM(IND ) + EAD
            END IF
         END DO
      END DO

!     --- calculate the diffraction coefficient

      DO IND = 1, MCGRD
         IF ( DENOM(IND).GT.0.0 ) THEN
            TMP = 2.*LAPE(IND)/DENOM(IND)
         ELSE
            TMP = 0.
         END IF
         IF (TMP.LT.-1.) THEN
            DIFPARAM(IND) = 0.
         ELSE
            DIFPARAM(IND) = SQRT(1.+TMP)
         END IF
      END DO
      CALL SWEXCHG(DIFPARAM(:),KGRPNT)                                    40.41
!JAC      CALL SWEXCHG(DIFPARAM(:),0,KGRPNT)                                  40.41
      IF (STPNOW()) RETURN                                                40.41

!     --- calculate spatial derivatives of DIFPARAM

!     --- loop over all X-connections
      DO IX = MAX(IX1,2), MIN(IX2,MXC-1)                                  40.41
         DO IY = IY1, IY2                                                 40.41
            IND  = KGRPNT(IX  ,IY)
            INDL = KGRPNT(IX-1,IY)
            INDR = KGRPNT(IX+1,IY)
            IF (NUMOBS.EQ.0) THEN                                         40.41
               NOOBST=.TRUE.                                              40.41
            ELSE IF (CROSS(1,IND).EQ.0) THEN                              40.41
               NOOBST=.TRUE.                                              40.41
            ELSE                                                          40.41
               NOOBST=.FALSE.                                             40.41
            END IF                                                        40.41
            IF (NOOBST                                                    40.41
     &          .AND. DEP2(IND ).GT.DEPMIN
     &          .AND. DEP2(INDL).GT.DEPMIN
     &          .AND. DEP2(INDR).GT.DEPMIN) THEN
               IF ( OPTG.EQ.1 ) THEN
                  DXLOC = DX
               ELSE IF ( OPTG.EQ.3 ) THEN                                 40.80
                  DXLOC = 0.5*(XCGRID(IX+1,IY)-XCGRID(IX-1,IY))
               END IF
               IF ( KSPHER.GT.0 ) THEN                                    40.68
                  CSLAT = COS(DEGRAD*(YOFFS+YCGRID(IX,IY)))               40.68
                  DXLOC = DXLOC * LENDEG * CSLAT                          40.68
               ENDIF                                                      40.68
               DXLOC = ABS(DXLOC)
               IF (EQREAL(DXLOC,0.)) DXLOC=0.01
               TMP = (DIFPARAM(INDR) - DIFPARAM(INDL))/(2.*DXLOC)
               DIFPARDX(IND) = DIFPARDX(IND) + TMP
            END IF
         END DO
      END DO

!     --- loop over all Y-connections
      DO IX = IX1, IX2                                                    40.41
         DO IY = MAX(IY1,2), MIN(IY2,MYC-1)                               40.41
            IND  = KGRPNT(IX,IY  )
            INDB = KGRPNT(IX,IY-1)
            INDT = KGRPNT(IX,IY+1)
            IF (NUMOBS.EQ.0) THEN                                         40.41
               NOOBST=.TRUE.                                              40.41
            ELSE IF (CROSS(2,IND).EQ.0) THEN                              40.41
               NOOBST=.TRUE.                                              40.41
            ELSE                                                          40.41
               NOOBST=.FALSE.                                             40.41
            END IF                                                        40.41
            IF (NOOBST                                                    40.41
     &          .AND. DEP2(IND ).GT.DEPMIN
     &          .AND. DEP2(INDB).GT.DEPMIN
     &          .AND. DEP2(INDT).GT.DEPMIN) THEN
               IF ( OPTG.EQ.1 ) THEN
                  DYLOC = DY
               ELSE IF ( OPTG.EQ.3 ) THEN                                 40.80
                  DYLOC = 0.5*(YCGRID(IX,IY+1)-YCGRID(IX,IY-1))
               END IF
               IF ( KSPHER.GT.0 ) DYLOC = DYLOC * LENDEG                  40.68
               DYLOC = ABS(DYLOC)
               IF (EQREAL(DYLOC,0.)) DYLOC=0.01
               TMP = (DIFPARAM(INDT) - DIFPARAM(INDB))/(2.*DYLOC)
               DIFPARDY(IND) = DIFPARDY(IND) + TMP
            END IF
         END DO
      END DO

!     --- rotation over ALPC needed for non-standard orientation
!         of the computational grid

      IF ( OPTG.EQ.1 ) THEN
         DO IND = 1, MCGRD
            TMP_X = DIFPARDX(IND)
            TMP_Y = DIFPARDY(IND)
            DIFPARDX(IND) = COSPC * TMP_X - SINPC * TMP_Y
            DIFPARDY(IND) = SINPC * TMP_X + COSPC * TMP_Y
         END DO
      END IF

!     --- test output
      IF (NPTST .GT. 0) THEN
         WRITE (PRTEST, 81) IDIFFR
  81     FORMAT (' test DIFPAR, IDIFFR=',I1,
     &          /, '     ampl        laplacian ',
     &             '     difpar      @/@x         @/@y')
         DO IS = 1, NPTST
            IX  = XYTST(2*IS-1)
            IY  = XYTST(2*IS)
            IND = KGRPNT(IX,IY)
            WRITE (PRTEST, 82) EN(IND), LAPE(IND),
     &                       DIFPARAM(IND),
     &                       DIFPARDX(IND), DIFPARDY(IND)
  82        FORMAT (10(1X,E12.4))
         END DO
      END IF

!     --- deallocate arrays
      DEALLOCATE (EN, LAPE, DENOM, K, CG)
      DEALLOCATE (ENTMP)

!     End of subroutine DIFPAR
      RETURN
      END
