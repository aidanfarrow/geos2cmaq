       SUBROUTINE LR_INTERP( L_RATINT, XA, YA, N, X, Y, DELY )

C*************************************************************************
C
C  FUNCTION: Interpolates a value Y for a given X from the arrays XA and
C            YA. The flag L_RATINT determines whether linear or rational
C            function interpolation is done.
C
C  PRECONDITIONS: Extrapolation will be performed unless controlled by 
C                 the calling routine
C 
C  KEY SUBROUTINES/FUNCTIONS CALLED: None
C
C  REVISION HISTORY: Prototype created by Jerry Gipson, January, 1998
C                      Rational Function Interpolation is from Numerical
C                      Recipes (Press et al., 19??)             
C                    Linear interpolation equation modified by JG 5/27/99 
C                      to better treat large conc gradients
C                    Improved Linear interpolation algorithm by JG 4/18/00
C                    for interpolants close to interval end points
C
C*************************************************************************
      IMPLICIT NONE 

C..INCLUDES: None
      
C..ARGUMENTS:
      INTEGER  N         ! Number of values in arrays XA and YA

      LOGICAL  L_RATINT  ! Flag for rational function interpolation

      REAL DELY          ! Error estimate rational function interpolation
      REAL X             ! Value of independent variable to be interpolated 
      REAL Y             ! Interpolated value of dependent variable
      REAL XA( * )       ! Independent variable array
      REAL YA( * )       ! Dependent variable array
                                           
C..PARAMETERS:
      INTEGER     NMAX       ! Maximum number of points in arrays AX and YA
      PARAMETER ( NMAX = 100 )

      REAL        TINY       ! Tiny number
      PARAMETER ( TINY = 1.0E-35 )

      REAL        EPS        ! Small number
      PARAMETER ( EPS = 1.0E-05 )

C..EXTERNAL FUNCTIONS: None

C..SAVED LOCAL VARIABLES: None

C..SCRATCH LOCAL VARIABLES:
      CHARACTER( 16 )  PNAME    ! Program Name
      CHARACTER( 80 ) MSG      ! Log message

      INTEGER I, M           ! Loop indices
      INTEGER NS             ! Rat Func temporary variable

      REAL DX                ! Incremental delta of independent variable
c      REAL DY                ! Incremental delta of dependent variable
      REAL SX                ! Incremental independent value for interpolation
      REAL SLP               ! Slope for linear interpolation


      REAL H, HH, T, DD, W   ! Rat Func temporary variables

      REAL C( NMAX )         ! Rat Func temporary variable
      REAL D( NMAX )         ! Rat Func temporary variable

C*************************************************************************
      DATA PNAME /'LR_INTERP' /

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Linear interpolation section
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      IF( .NOT. L_RATINT ) THEN

         DELY = 0.0

         IF( ( XA( 1 ) .LT. XA( 2 )  .AND. X .LE. XA( 1 ) ) .OR.
     &       ( XA( 1 ) .GT. XA( 2 )  .AND. X .GE. XA( 1 ) ) ) THEN 

            DX = XA( 2 ) - XA( 1 )

            IF( DX .EQ. 0.0 ) THEN
               MSG = 'Invalid Independent variables for interpolation'
               CALL M3ERR( PNAME, 0 , 0, MSG, .TRUE. )
            ENDIF

            Y = YA( 1 ) + ( ( X - XA( 1 ) ) / DX ) * YA( 1 )

            RETURN

         ENDIF

         IF( ( XA( N ) .GT. XA( N - 1 ) .AND. X .GE. XA( N ) ) .OR.
     &       ( XA( N ) .LT. XA( N - 1 ) .AND. X .LE. XA( N ) ) ) THEN 

            DX = XA( N ) - XA( N - 1 )

            IF( DX .EQ. 0.0 ) THEN
               MSG = 'Invalid Independent variables for interpolation'
               CALL M3ERR( PNAME, 0 , 0, MSG, .TRUE. )
            ENDIF

            Y = YA( N ) + ( ( X - XA( N ) ) / DX ) * YA( N - 1 )

            RETURN

         ENDIF

         DO I = 1, N - 1

            DX = ABS( XA( I + 1 ) - XA( I ) )
c            DY = YA( I + 1 ) - YA( I )
            SX = ABS( X - XA( I ) )

            IF ( SX - DX .LT. EPS ) THEN

               IF( DX .EQ. 0.0 ) THEN
                  MSG = 'Invalid Independent variables for interpolation'
                  CALL M3ERR( PNAME, 0 , 0, MSG, .TRUE. )
               ENDIF

c               Y = YA( I ) + ( ( X - XA( I ) ) / 
c     &             ( XA( I + 1 ) - XA( I ) ) ) * DY

               SLP = ( X - XA( I ) ) / ( XA( I + 1 ) - XA( I ) )
               IF( SLP .GT.  0.99999 ) SLP = 1.0
               IF( SLP .LT.  0.00001 ) SLP = 0.0

               Y = ( 1.0 - SLP ) * YA( I ) + SLP * YA( I + 1 )

               RETURN

            ENDIF

         ENDDO

         MSG = 'No interval found for linear interpolation'
         CALL M3ERR( PNAME, 0 , 0, MSG, .TRUE. )

      ENDIF
 
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c  Rational function interpolation section
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      NS = 1
      HH = ABS( X - XA( 1 ) )

      DO I = 1, N
         H = ABS( X -XA( I ) )
         IF( H .EQ. 0. )THEN
            Y = YA( I )
            DELY = 0.0
            RETURN
         ELSEIF ( H .LT. HH ) THEN
            NS = I
            HH = H
         ENDIF
         C( I ) = YA( I )
         D( I ) = YA( I ) + TINY
      ENDDO

      Y = YA( NS )
      NS = NS - 1

      DO M = 1, N - 1
         DO I = 1, N - M
            W = C( I + 1 ) - D( I )
            H = XA( I + M ) - X
            T = ( XA( I ) - X ) * D( I ) / H
            DD = T - C( I + 1 )

            IF( DD .EQ. 0. ) THEN
               MSG = 'Rational function interpolation error'
               CALL M3ERR( PNAME, 0 , 0, MSG, .TRUE. )
            ENDIF
            DD = W / DD
            D( I ) = C( I + 1 ) * DD
            C( I ) = T * DD
         ENDDO

         IF( 2 * NS .LT. N - M )THEN
            DELY = C( NS + 1 )
         ELSE
            DELY = D( NS )
           NS = NS - 1
         ENDIF

         Y = Y + DELY

      ENDDO

      RETURN

      END
