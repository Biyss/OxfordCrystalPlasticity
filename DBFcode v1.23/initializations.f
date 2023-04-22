!     Sept. 26th, 2022
!     Eralp Demir
!
!     This module includes initialization scripts
!
      module initializations
      implicit none
      contains
!
!
!
!
!     Subroutines that need to run once at the beginning of calculations
      subroutine initialize_once

      use meshprop, only : feprop
      use useroutputs, only: defineoutputs
      use fileIO, only: fileread
      implicit none
!     
      
      call fileread
      write(*,*) '1. ABAQUS "*.INP" file has been read!'
!
!
!     1. Enter mesh/element properties
!     to get number of integration points for array allocation
      call feprop
      write(*,*) '1. Mesh initialization completed!'
!
!
!     2. Allocate arrays
      call allocate_arrays
      write(*,*) '2. Array allocation completed!'
!
!     3. Initialize identity matrices
      call initialize_identity
      write(*,*) '3. Identity tensors initialized!'
!
!     4. Define outputs
!     Based on the flag: "readfromprops = 0 / 1"
!     Will be either read from PROPS or from useroutputs.f
      call defineoutputs
      write(*,*) '4. Outputs are defined using useroutputs.f!'
!
!
!
!
      return
      end subroutine initialize_once
!
!
!
!
!
!     Subroutines that need to run once at the beginning of calculations
      subroutine initialize_atfirstinc(noel,npt,coords,nprops,
     + props,temp,nstatv)
      use userinputs, only: constanttemperature, temperature, maxnslip
      use globalvariables, only: 
     + materialid, ipcoords, numdim,
     + statev_gmatinv, statev_gmatinv_t, ip_init,
     + numslip_all, numscrew_all, phaseid_all,
     + statev_tauc, statev_tauc_t, 
     + dirc_0_all, norc_0_all,
     + trac_0_all, linc_0_all,
     + forestproj_all, slip2screw_all, screw_all,
     + statev_ssd, statev_ssd_t,
     + statev_ssdtot, statev_ssdtot_t,
     + statev_tausolute, statev_tausolute_t,
     + statev_loop, statev_loop_t, 
     + caratio_all, cubicslip_all,
     + Cc_all, gf_all, G12_all,
     + alphamat_all, burgerv_all,
     + slipmodel_all, slipparam_all,
     + creepmodel_all, creepparam_all,
     + hardeningmodel_all, hardeningparam_all,
     + irradiationmodel_all, irradiationparam_all,
     + sintmat1_all, sintmat2_all,
     + hintmat1_all, hintmat2_all,
     + statev_outputs, nstatv_outputs 
!
      use irradiation, only: calculateintmats4irradmodel2
      use usermaterials, only: materialparam
      use userinputs, only: maxnparam, maxnmaterial
      use utilities, only: rotord4sig
      use useroutputs, only: checkoutputs
      use errors, only: error
      implicit none
!     Element number
      integer, intent(in) :: noel
!     Integration point
      integer, intent(in) :: npt
!     Number of properties
      integer, intent(in) :: nprops
!     Ip coordinates
      real(8), intent(in) :: coords(3)
!     State variables
      real(8), intent(in) :: props(nprops)
!     Abaqus temperature
      real(8), intent(in) :: temp
!     Number of state variables
      integer, intent(in) :: nstatv
!
!     Internal variables
!     Flag for reading from PROPS vector
      integer readfromprops
!     Euler angles - Bunge convention
      real(8) :: Euler(3)
!     Crystal to sample transformation matrix
      real(8) :: gmatinv(3,3)
!     Phase id
      integer :: phaid
!     Number of slip systems
      integer :: nslip
!     Number of screw systems
      integer :: nscrew
!     Material id
      integer :: matid
!     Slip model
      integer :: slipmodel
!     Slip parameters
      real(8) :: slipparam(maxnparam)
!     Creep model
      integer :: creepmodel
!     Creep parameters
      real(8) :: creepparam(maxnparam)
!     Hardening model      
      integer :: hardeningmodel
!     Hardening parameters
      real(8) :: hardeningparam(maxnparam)
!     Irradiation model
      integer :: irradiationmodel
!     Irradiation parameters
      real(8) :: irradiationparam(maxnparam)
!     Cubic slip for fcc nickel superalloys only
      integer :: cubicslip
!     Material temperature
      real(8) :: mattemp
!     c/a ratio for hexagonal materials
      real(8) :: caratio
!     Crystal elasticity matrix
      real(8) :: Cc(6,6)
!     Geometric factor
      real(8) :: gf
!     Shear modulus
      real(8) :: G12
!     Thermal expansion coefficient matrix in crystal lattice
      real(8) :: alphamat(3,3)
!     Burgers vector
      real(8) :: burgerv(maxnslip)
!     Screw systems
      integer :: screw(maxnslip)
!     Initial critical resolved shear stress
      real(8) :: tauc_0(maxnslip)
!     Initial dislocation density
      real(8) :: rho_0(maxnslip)
!     Interaction matrices
!     Strength interaction between dislocations
      real(8) :: sintmat1(maxnslip,maxnslip)
!     Strength interaction dislocation loops related with irradiation
      real(8) :: sintmat2(maxnslip,maxnslip)
!     Latent hardening
      real(8) :: hintmat1(maxnslip,maxnslip)
!     Hardening interaction matrix between dislocations
      real(8) :: hintmat2(maxnslip,maxnslip)
!     Allocatable arrays
!     Slip direction
      real(8) :: dirc(maxnslip,3)
!     Slip plane normal
      real(8) :: norc(maxnslip,3)
!     Transverse direction
      real(8) :: trac(maxnslip,3)
!     Slip line direction
      real(8) :: linc(maxnslip*2,3)
!     Forest projection operator
      real(8) :: forestproj(maxnslip,maxnslip*2)
!     Slip to screw system mapping
      real(8) :: slip2screw(maxnslip,maxnslip)
!     Variables used in the calculations here within this subroutine
!     Elasiticity
      real(8) :: C11, C12, C44, C13, C33
      real(8) :: C23, C22, C55, C66
!     Thermal expansion 
      real(8) :: alpha1, alpha2, alpha3
!
!     Dummy variables
      integer i, j, ind, is, nloop, dum
!
!
!     Reset arrays
      burgerv=0.; tauc_0=0.; rho_0=0.
      sintmat1=0.; sintmat2=0.
      hintmat1=0.; hintmat2=0.
      dirc=0.; norc=0.; trac=0.; linc=0.
      forestproj=0.; slip2screw=0.; screw=0
      slipparam=0.;creepparam=0.
      hardeningparam=0.; irradiationparam=0.
!
!
!
!     Calculation for only once (require NSTATV)
!     This is done here because NSTATV is available in UMAT
!     Can't be done at UEXTERNALDB(LOP=0)
      if (ip_init(1,1) == 0) then
!
!         Check the number state variables defined in DEPVAR 
!         matches the outputs defined by the user (in useroutputs.f or in PROPS)
          call checkoutputs(nstatv)
!
      end if
!
!
!!     Element number counter
!      if (sum(ip_init(noel,:))==0) then
!          numel = numel + 1
!      end if
!
!
!
!     Initialization flag
      ip_init(noel,npt) = 1
!
!     Read integration point coordinates
!     Assign and store at a global variable
      ipcoords(noel,npt,1:numdim) = coords(1:numdim)
!
!     Read from PROPS
      readfromprops = int(props(6))
      
!     Material id (Phase id)
      matid = int(props(5))
!
!     Save material id
      materialid(noel,npt)=matid
!
!     Initialize the ginv from Euler angles
!     phi1: 1st on the property list
      Euler(1)=props(1)
!     Phi: 2nd on the property list
      Euler(2)=props(2)
!     phi2: 3rd on the property list
      Euler(3)=props(3)
!
!
!
!
!      write(*,*) 'noel', noel
!      write(*,*) 'npt', npt
!      write(*,*) 'matid', matid
!      write(*,*) 'Euler', Euler
!
!
!
!
!
!
!     Calculate inverse of the orientation matrix
      call initialize_orientations(Euler,gmatinv)
!
!     Assign the initial orientations
      statev_gmatinv(noel,npt,:,:)=gmatinv
      statev_gmatinv_t(noel,npt,:,:)=gmatinv
!
!
!
!
!
!     Decision on using ABAQUS temperature
      if (constanttemperature.eq.1) then
!
!
!         Assign
          mattemp = temperature
!
      else if (constanttemperature.eq.0) then
!
!         Use ABAQUS temperature (must be in K)
          mattemp = temp
!
!
      else
!         Temperature flag is not assined correctly
          call error(5)
!
      endif
!
!
!     If the properties are defined at "usermaterials.f"
      if (readfromprops==0) then
!
!         Enter materials subroutine once for every ip to get number of slip systems    
          call materialparam(matid,mattemp,
     + phaid,nslip,nscrew,caratio,cubicslip,Cc,
     + gf,G12,alphamat,burgerv,tauc_0,rho_0,
     + slipmodel,slipparam,creepmodel,creepparam,
     + hardeningmodel,hardeningparam,
     + irradiationmodel,irradiationparam,
     + sintmat1,sintmat2,hintmat1,hintmat2)
!
!     If material properies are defined in PROPS vector
      elseif (readfromprops==1) then
      
!         Phase id is the same as material id
          phaid = int(props(5))
              
!         Number of slip systems
          nslip = int(props(7))
              
!         Number of screw systems
          nscrew = int(props(8)) 
              
!         cubic slip flag
          cubicslip = int(props(9))
            
       
          
!         geometric factor
          gf = props(11)
              
!         Elastic constants
          C11 = props(12)
          C12 = props(13)
          C44 = props(14)
          
!         Shear modulus
          G12 = C44
!              
              
!         If cubic material - 3 constants
          if (phaid<3) then

!             Elasticity matrix of a cubic material
              Cc = 0.
              Cc(1,1:3) = (/ C11, C12, C12 /)
              Cc(2,1:3) = (/ C12, C11, C12 /)
              Cc(3,1:3) = (/ C12, C12, C11 /)
              Cc(4,4) = C44
              Cc(5,5) = C44
              Cc(6,6) = C44
                  
                  
!         If hexagonal material - 5 constants
          elseif (phaid==3) then
                  
!             Read the remaning parameters
              C13 = props(15)
              C33 = props(16)
                  
!             Elasticity matrix of a hexagonal material
              Cc = 0.
              Cc(1,1:3) = (/ C11, C12, C13 /)
              Cc(2,1:3) = (/ C12, C11, C13 /)
              Cc(3,1:3) = (/ C13, C13, C33 /)
              Cc(4,4) = C44
              Cc(5,5) = C44
              Cc(6,6) = 0.5*(C11-C12)
                  
!         If tetragonal material - 9 constants
          elseif (phaid==4) then
                  
!             Read the remaning parameters
              C23 = props(17)
              C22 = props(18)
              C55 = props(19)
              C66 = props(20)
                  
!             Elasticity matrix of a ot material
              Cc = 0.
              Cc(1,1:3) = (/ C11, C12, C13 /)
              Cc(2,1:3) = (/ C12, C22, C23 /)
              Cc(3,1:3) = (/ C13, C23, C33 /)
              Cc(4,4) = C44
              Cc(5,5) = C55
              Cc(6,6) = C66
                                    
                  
                  
          endif
          
!         c/a ratio
          caratio = int(props(21))
          
          
!         Thermal expansion coefficients
          alpha1 = props(22)
          alpha2 = props(23)
          alpha3 = props(24)
          alphamat = 0.
          alphamat(1,1) = alpha1 
          alphamat(2,2) = alpha2 
          alphamat(3,3) = alpha3
          

          
          
          
!         Slip model
          slipmodel = int(props(25))
          
!         Slip model parameters
          do i = 1, maxnparam
              
              ind = i + 25
              
              slipparam(i) = props(ind)
              
              
          end do
          
!         Creep model
          creepmodel = int(props(36))
          
!         Creep model parameters
          do i = 1, maxnparam
              
              ind = i + 36
              
              creepparam(i) = props(ind)
              
              
          end do          
          
 
!         Hardening model
          hardeningmodel = int(props(47))
          
!         Hardening model parameters
          do i = 1, maxnparam
              
              ind = i + 47
              
              hardeningparam(i) = props(ind)
              
              
          end do          
          
          
!         Irradiation model
          irradiationmodel = int(props(58))
          
          
!         Irradiation model parameters
          do i = 1, maxnparam
              
              ind = i + 58
              
              irradiationparam(i) = props(ind)
              
              
          end do                
          
          
         
          
!         Strength interaction matrix - 1 coefficients
!         PROPS(69-78)
          
!         Strength interaction matrix - 2 coefficients
!         PROPS(79-88)
          
!         Hardening interaction matrix - 1 coefficients
!         PROPS(89-98)
          
!         Hardening interaction matrix - 2 coefficients
!         PROPS(99-108)
          
!         They are undefined for now - set to identity
!         Interaction matrices
!         Initially set all to identity
          sintmat1=0.
          sintmat2=0.
          hintmat1=0.
          hintmat2=0.
          do is = 1, maxnslip
              sintmat1(is,is)=1.
              sintmat2(is,is)=1.
              hintmat1(is,is)=1.
              hintmat2(is,is)=1.
          end do          
          
          
!         Overwrite user-defined outputs in useroutputs.f
!         Reset number of state variables
          nstatv_outputs = 0
!         Reset the flags for outputs
          statev_outputs = 0
          do i = 1, 20
              
              ind = i + 108
              
              dum = int(PROPS(ind))
              
              statev_outputs(i) = dum
              
!             Count the total number of outputs
              if (dum ==1) then
                  nstatv_outputs =  nstatv_outputs + 1
              end if
              
              
          end do
          
          
          
!         Assign slip system quantities
          
!         Initial dislocation density
          rho_0=0.
          do is = 1, maxnslip
              
              ind = is + 128
              
              rho_0(is) = props(ind)
              
              
          end do
          
              
!         Burgers vector
          burgerv=0.
          do is = 1, maxnslip
              
              ind = is + 158
              
              burgerv(is) = props(ind)
              
              
          end do          
          

!         Initial critical resolves shear strength
          tauc_0=0.
          do is = 1, maxnslip
              
              ind = is + 188
              
              tauc_0(is) = props(ind)
              
              
          end do   
          
!         PROPS(219-250) are intentionally left empty!
          
          
      endif
              
!
!
!     Initialize phase-id of the material
      phaseid_all(matid)=phaid
!
!
!     Initialize number of slip systems
      numslip_all(matid)=nslip
!
!     Initialize number of screw systems
!     Required for GND calculations
      numscrew_all(matid)=nscrew
!
!
!     Initialize crsss
      statev_tauc(noel,npt,1:maxnslip)=tauc_0
      statev_tauc_t(noel,npt,1:maxnslip)=tauc_0
!
!     Initialize ssd density per slip system
      statev_ssd(noel,npt,1:maxnslip)=rho_0
      statev_ssd_t(noel,npt,1:maxnslip)=rho_0
!
!     Initialize total ssd density
      statev_ssdtot(noel,npt)=rho_0(1)
      statev_ssdtot_t(noel,npt)=rho_0(1)
!
!
!     Initialize irradiation parameters
      if (irradiationmodel==1) then
!         Initialize solute strength
          statev_tausolute(noel,npt)=irradiationparam(1)
          statev_tausolute_t(noel,npt)=irradiationparam(1)
!
!
      elseif (irradiationmodel==2) then
!         Initialize defect loop density
          nloop=int(irradiationparam(1))
          do i = 1, nloop
              statev_loop(noel,npt,i)=irradiationparam(1+i)*
     + irradiationparam(1+nloop+i)
              statev_loop_t(noel,npt,i)=irradiationparam(1+i)*
     + irradiationparam(1+nloop+i)
          end do
!
      end if    
!
!
!     Initialize caratio
      caratio_all(matid)=caratio
!
!
!     Initialize cubicslip
      cubicslip_all(matid)=cubicslip
!
!     Initialize elasticity in crystal frame
      Cc_all(matid,1:6,1:6)=Cc
!
!     Initialize geometric factor
      gf_all(matid)=gf
!
!     Initialize shear modulus
      G12_all(matid)=G12
!
!     Initialize thermal expansion matrix
      alphamat_all(matid,1:3,1:3)=alphamat
!
!     Initialize burgers vector
      burgerv_all(matid,1:maxnslip)=burgerv
!
!
!
!     assign the global variables
!
!     slip model
      slipmodel_all(matid)=slipmodel
!     slip parameters
      slipparam_all(matid,:)=slipparam
!     creep model
      creepmodel_all(matid)=creepmodel
!     creep parameters
      creepparam_all(matid,:)=creepparam
!     hardening model
      hardeningmodel_all(matid)=hardeningmodel
!     hardening parameters
      hardeningparam_all(matid,:)=hardeningparam
!     irradiation model
      irradiationmodel_all(matid)=irradiationmodel
!     irradiation parameters
      irradiationparam_all(matid,:)=irradiationparam
!
!
!
!
!
!     Initialize initial (undeformed) slip vectors
!     This is needed once per element since the material is different
      call initialize_slipvectors(phaid,nslip,nscrew,caratio,
     + screw,dirc,norc,trac,linc,forestproj,slip2screw)
!
!
!     Irradiation strength and hardening matrices are a function of slip vectors
!     Therefore, the interaction matrices need to be computed here, 
!     after the calculation of slip vectors
      if (irradiationmodel==2) then
          call calculateintmats4irradmodel2(nslip,dirc,norc,
     + irradiationparam,sintmat2,hintmat2)
      end if
!
!     assign the interaction matrices
!     Strength interaction between dislocations
      sintmat1_all(matid,:,:) = sintmat1
!     Strength interaction dislocation loops related with irradiation
      sintmat2_all(matid,:,:) = sintmat2
!     Latent hardening
      hintmat1_all(matid,:,:) = hintmat1
!     Hardening interaction matrix between dislocations
      hintmat2_all(matid,:,:) = hintmat2
!
!
!     assign undeformed slip directions
      dirc_0_all(matid,1:nslip,1:3) = dirc(1:nslip,1:3)
      norc_0_all(matid,1:nslip,1:3) = norc(1:nslip,1:3)
      trac_0_all(matid,1:nslip,1:3) = trac(1:nslip,1:3)
      linc_0_all(matid,1:nslip+nscrew,1:3) = linc(1:nslip+nscrew,1:3)
!
!     Forest projection operator
      forestproj_all(matid,1:nslip,1:nslip+nscrew) =
     + forestproj(1:nslip,1:nslip+nscrew)
!
!
!     Slip to screw mapping
      slip2screw_all(matid,1:nscrew,1:nslip) =
     + slip2screw(1:nscrew,1:nslip)
!
!     Screw systems
      screw_all(matid,1:nscrew)=screw(1:nscrew)
!
!
      return
      end subroutine initialize_atfirstinc
!
!
!
!     Arrays allocated      
      subroutine allocate_arrays
      use globalvariables, only : numel, numpt, numdim, nnpel,
     + materialid, phaseid_all, numslip_all, numscrew_all,
     + dirc_0_all, norc_0_all, trac_0_all, linc_0_all,
     + forestproj_all, slip2screw_all, screw_all,
     + ip_init, gradip2ip, ipcoords, 
     + statev_gmatinv, statev_gmatinv_t,
     + statev_gammasum, statev_gammasum_t,
     + statev_jacobi, statev_jacobi_t, statev_Fth, statev_Fth_t,
     + statev_gammadot, statev_gammadot_t, statev_Fp, statev_Fp_t,
     + statev_sigma, statev_sigma_t, statev_tauc, statev_tauc_t,
     + statev_maxx, statev_maxx_t, statev_Eec, statev_Eec_t,
     + statev_gnd, statev_gnd_t, statev_ssd, statev_ssd_t,
     + statev_forest, statev_forest_t, statev_substructure,
     + statev_substructure_t, statev_tausolute, statev_tausolute_t,
     + statev_totgammasum, statev_totgammasum_t,
     + statev_evmp, statev_evmp_t, statev_ssdtot, statev_ssdtot_t,
     + statev_Lambda, statev_Lambda_t, statev_curvature,
     + statev_loop, statev_loop_t, 
     + caratio_all, cubicslip_all, Cc_all, gf_all,
     + G12_all, alphamat_all, burgerv_all,
     + slipmodel_all, slipparam_all,
     + creepmodel_all, creepparam_all,
     + hardeningmodel_all, hardeningparam_all,
     + irradiationmodel_all, irradiationparam_all,
     + sintmat1_all, sintmat2_all, 
     + hintmat1_all, hintmat2_all
      use userinputs, only : maxnslip, maxnparam,
     + maxnmaterial, maxnloop
      implicit none
      integer i, j, k
!
!
!
!     For multi material case with varying number of slip systems
      allocate(materialid(numel,numpt))
      materialid=0
!
!     Initial crystal to sample transformation   
!
!     For multi material case with varying number of slip systems
      allocate(numslip_all(maxnmaterial))
      numslip_all=0
!
!     For multi material case with varying number of screw systems
      allocate(numscrew_all(maxnmaterial))
      numscrew_all=0
      
!     Screw systems
      allocate(screw_all(maxnmaterial,maxnslip))
      screw_all=0
!
!
!     For multi material case with varying number of slip systems
      allocate(phaseid_all(maxnmaterial))
      phaseid_all=0
!
!     Allocate slip systems
      allocate(dirc_0_all(maxnmaterial,maxnslip,3))
      dirc_0_all=0.
      allocate(norc_0_all(maxnmaterial,maxnslip,3))
      norc_0_all=0.
      allocate(trac_0_all(maxnmaterial,maxnslip,3))
      trac_0_all=0.
      allocate(linc_0_all(maxnmaterial,maxnslip,3))
      linc_0_all=0.
!
!     Forest projections for GND
      allocate(forestproj_all(maxnmaterial,maxnslip,maxnslip*2))
      forestproj_all=0. 
!
!     Mapping for dislocations at slip sytems to screw systems for GND
      allocate(slip2screw_all(maxnmaterial,maxnslip,maxnslip))
      slip2screw_all=0. 
!
!
!     These are needed for GND calculations
      allocate(ipcoords(numel,numpt,numdim))
      ipcoords=0.
      allocate(ip_init(numel,numpt))
      ip_init=0 ! very important to set to zero initially
!
!     Allocate arrays related with shape functions
!     Note the gradient is 3-dimensional ("numdim" is not used!)
      allocate(gradip2ip(numel,numpt+1,3,numpt))
      gradip2ip=0.
!
!
!     Allocate state variables
      allocate(statev_gmatinv(numel,numpt,3,3))
      statev_gmatinv=0.
      allocate(statev_gmatinv_t(numel,numpt,3,3))
      statev_gmatinv_t=0.
!
      do i=1,numel
          do j=1,numpt
              do k=1,3
                  statev_gmatinv(i,j,k,k)=1.
                  statev_gmatinv_t(i,j,k,k)=1.
              end do
          end do
      end do
!
      allocate(statev_gammasum(numel,numpt,maxnslip))
      statev_gammasum=0.
      allocate(statev_gammasum_t(numel,numpt,maxnslip))
      statev_gammasum_t=0.
      allocate(statev_gammadot(numel,numpt,maxnslip))
      statev_gammadot=0.
      allocate(statev_gammadot_t(numel,numpt,maxnslip))
      statev_gammadot_t=0.
      allocate(statev_Fp(numel,numpt,3,3))
      statev_Fp=0.
      allocate(statev_Fp_t(numel,numpt,3,3))
      statev_Fp_t=0.
      allocate(statev_Fth(numel,numpt,3,3))
      statev_Fth=0.
      allocate(statev_Fth_t(numel,numpt,3,3))
      statev_Fth_t=0.
!
      do i=1,numel
          do j=1,numpt
              do k=1,3
                  statev_Fp(i,j,k,k)=1.
                  statev_Fp_t(i,j,k,k)=1.
                  statev_Fth(i,j,k,k)=1.
                  statev_Fth_t(i,j,k,k)=1.
              end do
          end do
      enddo
!
      allocate(statev_sigma(numel,numpt,6))
      statev_sigma=0.
      allocate(statev_sigma_t(numel,numpt,6))
      statev_sigma_t=0.
      allocate(statev_jacobi(numel,numpt,6,6))
      statev_jacobi=0.
      allocate(statev_jacobi_t(numel,numpt,6,6))
      statev_jacobi_t=0.
!
      do i=1,numel
          do j=1,numpt
              do k=1,6
                  statev_jacobi(i,j,k,k)=1.
                  statev_jacobi_t(i,j,k,k)=1.
              end do
          end do
      enddo
!
      allocate(statev_tauc(numel,numpt,maxnslip))
      statev_tauc=0.
      allocate(statev_tauc_t(numel,numpt,maxnslip))
      statev_tauc_t=0.
      allocate(statev_maxx(numel,numpt))
      statev_maxx=0.
      allocate(statev_maxx_t(numel,numpt))
      statev_maxx_t=0.
      allocate(statev_Eec(numel,numpt,6))
      statev_Eec=0.
      allocate(statev_Eec_t(numel,numpt,6))
      statev_Eec_t=0.
!
!     Incompatibility
      allocate(statev_Lambda(numel,numpt,9))
      statev_Lambda = 0.
      allocate(statev_Lambda_t(numel,numpt,9))
      statev_Lambda_t = 0.
!     Lattice curvature
      allocate(statev_curvature(numel,numpt,9))
      statev_curvature = 0.
!     
!     Allocated as twice the maxslip to leave space for screws
      allocate(statev_gnd(numel,numpt,2*maxnslip))
      statev_gnd=0.
      allocate(statev_gnd_t(numel,numpt,2*maxnslip))
      statev_gnd_t=0.
      allocate(statev_ssd(numel,numpt,maxnslip))
      statev_ssd=0.
      allocate(statev_ssd_t(numel,numpt,maxnslip))
      statev_ssd_t=0.
      allocate(statev_ssdtot(numel,numpt))
      statev_ssdtot=0.
      allocate(statev_ssdtot_t(numel,numpt))
      statev_ssdtot_t=0.
      allocate(statev_forest(numel,numpt,maxnslip))
      statev_forest=0.
      allocate(statev_forest_t(numel,numpt,maxnslip))
      statev_forest_t=0.
      allocate(statev_substructure(numel,numpt))
      statev_substructure=0.
      allocate(statev_substructure_t(numel,numpt))
      statev_substructure_t=0.
      allocate(statev_tausolute(numel,numpt))
      statev_tausolute=0.
      allocate(statev_tausolute_t(numel,numpt))
      statev_tausolute_t=0.
      allocate(statev_totgammasum(numel,numpt))
      statev_totgammasum=0.
      allocate(statev_totgammasum_t(numel,numpt))
      statev_totgammasum_t=0.
      allocate(statev_evmp(numel,numpt))
      statev_evmp=0.
      allocate(statev_evmp_t(numel,numpt))
      statev_evmp_t=0.
!     allocate as sparse array
      allocate(statev_loop(numel,numpt,maxnloop))
      statev_loop=0.
      allocate(statev_loop_t(numel,numpt,maxnloop))
      statev_loop_t=0.
!
!
!     Material parameters
      allocate(caratio_all(maxnmaterial))
      caratio_all=0.
      allocate(cubicslip_all(maxnmaterial))
      cubicslip_all=0
      allocate(Cc_all(maxnmaterial,6,6))
      Cc_all=0.
      allocate(gf_all(maxnmaterial))
      gf_all=0.
      allocate(G12_all(maxnmaterial))
      G12_all=0.
      allocate(alphamat_all(maxnmaterial,3,3))
      alphamat_all=0.
      allocate(burgerv_all(maxnmaterial,maxnslip))
      burgerv_all=0.
!
!
!     Material model parameters
      allocate(slipmodel_all(maxnmaterial))
      slipmodel_all=0
      allocate(slipparam_all(maxnmaterial,maxnparam))
      slipparam_all=0.
      allocate(creepmodel_all(maxnmaterial))
      creepmodel_all=0
      allocate(creepparam_all(maxnmaterial,maxnparam))
      creepparam_all=0.
      allocate(hardeningmodel_all(maxnmaterial))
      hardeningmodel_all=0
      allocate(hardeningparam_all(maxnmaterial,maxnparam))
      hardeningparam_all=0.     
      allocate(irradiationmodel_all(maxnmaterial))
      irradiationmodel_all=0
      allocate(irradiationparam_all(maxnmaterial,maxnparam))
      irradiationparam_all=0.
!
!
!     Interaction matrices
      allocate(sintmat1_all(maxnmaterial,maxnslip,maxnslip))
      sintmat1_all=0.
      allocate(sintmat2_all(maxnmaterial,maxnslip,maxnslip))
      sintmat2_all=0.
      allocate(hintmat1_all(maxnmaterial,maxnslip,maxnslip))
      hintmat1_all=0.
      allocate(hintmat2_all(maxnmaterial,maxnslip,maxnslip))
      hintmat2_all=0.
!
!
      return
      end subroutine allocate_arrays
!      
!      
!      
!        
!      
!      
!      
!      
!      
!      
!      
!      
!	This subroutine assigns identity tensors
!	USES: I3(3,3),I6(6,6),I9(9,9),eijk(3,3,3)
	subroutine initialize_identity
	use globalvariables, only : I3, I6, I9, eijk
	implicit none
	integer :: i, j, k, l
!
	I3=0.
      I6=0.
      I9=0.
!
!	Identity matrix (3x3)
	do i=1,3
         I3(i,i)=1.
      enddo
!
!
!	Identity matrix (6x6)
      do i=1,6
         I6(i,i)=1.
      enddo
!
!	Identity matrix (9x9)
      do i=1,9
         I9(i,i)=1.
      enddo
!
!
!     Permutation symbol (3x3x3)
      eijk=0.
      eijk(1,2,3)=1.
      eijk(2,3,1)=1.
      eijk(3,1,2)=1.
      eijk(3,2,1)=-1.							
      eijk(2,1,3)=-1.
      eijk(1,3,2)=-1.
!
	return
	end subroutine initialize_identity      
!
!
!	This subroutine assigns orientations
	subroutine initialize_orientations(Euler,gmatinv)
      use utilities, only: Euler2ori
	implicit none
      real(8), intent(in)  :: Euler(3)
      real(8), intent(out) :: gmatinv(3,3)
      real(8)              :: g(3,3)
!
!
!     Sample to crystal transformation
      call Euler2ori(Euler,g)
!
!
!     Crystal to sample tranformation
      gmatinv = transpose(g)
!
!
      return
      end subroutine initialize_orientations      
!
!
!     All slip systems of different phases are initialized
!     1: BCC
!     2: FCC
!     3: HCP
!     4: alpha-uranium
!     Forest projections are initialized here!
!     The number of slip systems will be identified in materials card      
!     Slip directions      
      subroutine initialize_slipvectors(phaseid,nslip,nscrew,caratio,
     + screw,dirc,norc,trac,linc,forestproj,slip2screw)
      use userinputs, only : maxnslip
      use globalvariables, only :  dir1, nor1, dir2, nor2,
     + dir3h, nor3h, dir4, nor4
      use utilities, only: vecprod
      use errors, only: error
      implicit none
!     Inputs
      integer, intent(in) :: phaseid, nslip, nscrew
      real(8), intent(in) :: caratio
!     Outputs
      real(8), dimension(nslip,3), intent(out) :: dirc
      real(8), dimension(nslip,3), intent(out) :: norc
      real(8), dimension(nslip,3), intent(out) :: trac
      real(8), dimension(nslip+nscrew,3), intent(out) :: linc
      real(8), dimension(nslip,nslip+nscrew), intent(out) :: forestproj
      real(8), dimension(nscrew,nslip), intent(out) :: slip2screw
      integer, dimension(nscrew), intent(out) :: screw
!
!     Local variables used within this subroutine
      real(8) :: dir(30,3), nor(30,3)
      real(8) :: sdir(nslip+nscrew,3)
      real(8) :: res(3)
      integer :: is, i, j
!
!     caratio (c/a) ratio is only used for HCP materials
!     So, caratio can take any value for other phases than HCP
!
!     Reset arrays
      dirc=0.; norc=0.
      dir=0.; nor=0.
!
!     BCC phase
      if (phaseid == 1) then
!
!
!
!         Normalize slip directions and normals
          do is=1, 24
              dir(is,:) = dir1(is,:)/norm2(dir1(is,:))
!
              nor(is,:) = nor1(is,:)/norm2(nor1(is,:))
          end do
!
!         Assign the slip system
          dirc(1:nslip,1:3) = dir(1:nslip,1:3)
          norc(1:nslip,1:3) = nor(1:nslip,1:3)
!
!     FCC phase
      elseif (phaseid == 2) then
!
!
!
!
!         Normalize slip directions and normals
          do is=1,18
              dir(is,:) = dir2(is,:)/norm2(dir2(is,:))
!
              nor(is,:) = nor2(is,:)/norm2(nor2(is,:))
          end do
!
!
!         Assign the slip system
          dirc(1:nslip,1:3) = dir(1:nslip,1:3)
          norc(1:nslip,1:3) = nor(1:nslip,1:3)
!
!
!
!
!
!     HCP phase
      elseif (phaseid == 3) then
!
!         slip direction conversion
!         [uvtw]->[3u/2 (u+2v)*sqrt(3)/2 w*(c/a)])
          do is=1,30
              dir(is,1) = 3.*dir3h(is,1)/2.
              dir(is,2) = (dir3h(is,1) + 2.*dir3h(is,2))*sqrt(3.)/2.
              dir(is,3) = dir3h(is,4)*caratio
          end do
!
!
!         slip plane conversion
!         (hkil)->(h (h+2k)/sqrt(3) l/(c/a))
          do is=1,30
              nor(is,1) = nor3h(is,1)
              nor(is,2) = (nor3h(is,1) + 2.*nor3h(is,2))/sqrt(3.)
              nor(is,3) = nor3h(is,4)/caratio
          end do
!
!         Normalize slip directions and normals
          do is=1,30
              dir(is,:) = dir(is,:)/norm2(dir(is,:))
!
              nor(is,:) = nor(is,:)/norm2(nor(is,:))
          end do
!
!         Assign the slip system
          dirc(1:nslip,1:3) = dir(1:nslip,1:3)
          norc(1:nslip,1:3) = nor(1:nslip,1:3)
!
!
!     alpha-Uranium
      elseif (phaseid == 4) then
!
!         Normalize slip directions and normals
          do is=1,8
              dir(is,:) = dir4(is,:)/norm2(dir4(is,:))
!
              nor(is,:) = nor4(is,:)/norm2(nor4(is,:))
          end do           
!
!         Assign the slip system
          dirc(1:nslip,1:3) = dir(1:nslip,1:3)
          norc(1:nslip,1:3) = nor(1:nslip,1:3)
!
      else
!
!         Error message needed!
!         Phase number is not within the available options
          call error(4)
!
!
!
      end if
!
!
!     Transverse directions
      trac = 0.
      do i = 1, nslip
!
          call vecprod(dirc(i,1:3),norc(i,1:3),trac(i,1:3))
!
      end do
!
!
!
!     Dislocation line directions:
!
!     If screw systems are defined
      if (nscrew>0) then
!
!
!         Build up the screw slip systems      
          select case(phaseid) 
!
!
!
!             BCC
              case(1)
!
!             a/2<111>
              screw(1) = 1
              screw(2) = 2
              screw(3) = 3
              screw(4) = 6


!             FCC
              case(2)
!
              screw(1) = 1
              screw(2) = 2
              screw(3) = 3
              screw(4) = 4
              screw(5) = 6
              screw(6) = 8
!
!   
!
!             HCP 
              case(3) 
!
!             <a> slip
              screw(1) = 1 
              screw(2) = 2
              screw(3) = 3
!             <c+a>
              screw(4) = 7
              screw(5) = 8
              screw(6) = 9
              screw(7) = 10
              screw(8) = 11
              screw(9) = 12
!
!
!             
!             
          end select
!
      end if
!
!
!     slip2screw mapping
      slip2screw = 0.
!     Loop through the defined screw systems for equivalency
      do i = 1, nscrew
          
!         Screw system corresponding slip system
          is = screw(i)
          
!         Set the mapping to unity
          slip2screw(i,is) = 1.
          
          
!         Loop through all possible slip sytems
          do j = 1, nslip
          
!             Consider if it is a different slip system
              if (is/=j) then
              
!                 Caclulate the difference in Burgers vector
                  res = dirc(is,1:3) - dirc(j,1:3)
              
!                 If all the components of the vector is the same
                  if (norm2(res)==0.) then
                  
!                     Assign the component of mapping as unity
                      slip2screw(i,j) = 1. 
                      
                      
                  end if
          
              end if
          
!         Loop for slip sytems
          end do
          
!     Loop for screw systems
      end do
!
!
!
!
!     Calculate line directions for edge dislocations
      linc = 0.
      do i = 1, nslip
!
          call vecprod(dirc(i,1:3),norc(i,1:3),linc(i,1:3))
!
      end do
!
!     Calculate line directions for screw dislocations
!     If screw dislocations exist
      if (nscrew>0) then
!
          do i = 1, nscrew
!
              linc(nslip+i,1:3) = dirc(screw(i),1:3)
!
          end do
!
      end if
!
!
!     Compute forest projection operator for GNDs
      forestproj = 0.
      do i = 1, nslip
!
          do j = 1, nslip+nscrew
!
              forestproj(i,j) = 
     + dabs(dot_product(norc(i,1:3),linc(j,1:3)))
!
          enddo
!
      enddo
!
!
!
!
!
!
!
!      
      return
      end subroutine initialize_slipvectors
!
!
!
!
      end module initializations