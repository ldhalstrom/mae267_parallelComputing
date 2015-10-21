      PROGRAM CALCPIP
      IMPLICIT NONE

      include "mpif.h"
      REAL(KIND=8)  :: A,AK,B,BK,H,PI,SUBPI
      INTEGER :: K,MYID,N,NK,NPROCS
      INTEGER :: IERROR,TAG,STATUS

      ! INITIALIZE MPI
      CALL MPI_Init(IERROR)

      ! DETERMINE MY PROCESSOR ID
      ! ARGUMENTS: COMM, MYID, IERROR
      CALL MPI_Comm_rank(MPI_COMM_WORLD,MYID,IERROR)

      ! FIND OUT HOW MANY PROCESSORS ARE USED
      ! ARGUMENTS: COMM, NPROCS, IERROR
      CALL MPI_Comm_size(MPI_COMM_WORLD,NPROCS,IERROR)

      IF(MYID == 0) THEN
        !READ THE NUMBER OF SUB-INTERVALS
        PRINT *,'INPUT THE NUMBER OF SUB-INTERVALS'
        READ(*,*) N
        IF(N < NPROCS) GO TO 1000
      END IF

      ! BROADCAST THE NUMBER OF SUB-INTERVALS
      ! ARGUEMENTS: BUFFER, COUNT, DATATYPE, ROOT, COMM, IERROR
      CALL MPI_Bcast(N,1,MPI_INTEGER,0,MPI_COMM_WORLD,IERROR)

!     N = 10000   !DEFINE NUMBER OF INTEGRATION INTERVALS
      A = 0.0d0   !DEFINE INTERVAL START
      B = 1.0d0   !DEFINE INTERVAL STOP
      H  = (B-A)/REAL(N)

      ! N INTERVALS MUST BE EVENLY DIVISIBLE BY NPROCS
      NK = N/NPROCS
      AK = A + REAL(MYID)*REAL(NK)*H
      BK = AK + REAL(NK)*H

      ! COMPUTE LOCAL INTEGRAL
      CALL TRAP(AK,BK,NK,SUBPI)
 
      ! SET UP A MASTER-SLAVE RELATIONSHIP WHERE THE MASTER
      ! IS RESPONSIBLE FOR ACCUMULATING THE SUB-INTEGRALS
      ! AND WRITING OUT THE ANSWER
      IF(MYID == 0) THEN
        ! SUM UP THE INTEGRALS FROM THE OTHER PROCESSORS
        PI = SUBPI
        ! ADD THE SUBPI'S FROM THE OTHER PROCESSORS
        ! ARGUMENTS: BUFFER, COUNT, DATATYPE, SOURCE, TAG,
        !            COMM, STATUS, IERROR
        DO K = 1,NPROCS-1
           CALL MPI_Recv(SUBPI,1,MPI_DOUBLE_PRECISION,K,TAG, 
     &                   MPI_COMM_WORLD,STATUS,IERROR)
           PI = PI + SUBPI
        END DO
        PRINT *,'PI = ',PI
      ELSE
        ! SEND THE INTEGRAL TO THE MASTER
        ! ARGUMENTS: BUFFER, COUNT, DATATYPE, DEST, TAG,
        !            COMM, IERROR
        CALL MPI_Send(SUBPI,1,MPI_DOUBLE_PRECISION,0,TAG,
     &                MPI_COMM_WORLD,IERROR)
      END IF

      ! TERMINATE MPI
 1000 CALL MPI_Finalize(IERROR)

      STOP
      END
