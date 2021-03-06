!-*-f90-*-
subroutine nulibtable_reader(filename,include_Ielectron,include_epannihil_kernels, &
							include_bremsstrahlung_kernels,include_gang_kernels)
  
  use nulibtable
  use hdf5
  implicit none

  character(*),intent(IN) :: filename
  logical,intent(IN) :: include_Ielectron
  logical,intent(IN) :: include_epannihil_kernels
  logical,intent(IN) :: include_bremsstrahlung_kernels
  logical,intent(IN) :: include_gang_kernels

  !H5 stuff
  integer :: error,rank,cerror
  integer(HID_T) :: file_id,dset_id,dspace_id
  integer(HSIZE_T) :: dims1(1), dims2(2), dims3(3), dims4(4), dims5(5), dims6(6),dims7(7)!, etc....

  !local
  real*8, allocatable :: nulibtable_temp(:,:,:,:,:),gang_temp(:,:,:,:)
  real*8, allocatable :: nulibtable_temp2(:,:,:,:,:,:),nulibtable_temp3(:,:,:,:,:,:,:)
  real*8 :: timestamp
  integer :: startindex,endindex,index
  integer :: i,j,k,l,m

  cerror = 0

  !open HDF5 file, given filename                                                                                             
  call h5open_f(error)
  if (error.ne.0) then
     stop "Error reading in nulib file"
  endif
  
  call h5fopen_f(trim(adjustl(filename)), &
       H5F_ACC_RDONLY_F,file_id,error)
  if (error.ne.0) then
     write(*,*) trim(adjustl(filename))
     stop "Error reading in nulib table"
  endif

  !read scalars (rank=1, dims1(1) = 1)
  rank = 1
  dims1(1) = 1

  !first lets read number of species and number of groups 
  !and number of rho,temp, and ye points, also timestamp

  call h5dopen_f(file_id, "number_species",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_number_species, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error

  call h5dopen_f(file_id, "timestamp",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, timestamp, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error  

  call h5dopen_f(file_id, "number_groups",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_number_groups, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error

  allocate(nulibtable_energies(nulibtable_number_groups))
  allocate(nulibtable_inv_energies(nulibtable_number_groups))
  allocate(nulibtable_ewidths(nulibtable_number_groups))
  allocate(nulibtable_ebottom(nulibtable_number_groups))
  allocate(nulibtable_etop(nulibtable_number_groups))

  allocate(nulibtable_logenergies(nulibtable_number_groups))
  allocate(nulibtable_logetop(nulibtable_number_groups))

  call h5dopen_f(file_id, "nrho",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_nrho, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error

  call h5dopen_f(file_id, "ntemp",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_ntemp, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error

  call h5dopen_f(file_id, "nye",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_nye, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error

  !lets also read neutrino energies, bin bottoms,tops and widths
  rank = 1
  dims1(1) = nulibtable_number_groups
  call h5dopen_f(file_id, "neutrino_energies",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_energies, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error      
  
  !calculate inverse energies
  nulibtable_inv_energies = 1.0d0/nulibtable_energies


  call h5dopen_f(file_id, "bin_widths", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_ewidths, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  call h5dopen_f(file_id, "bin_bottom", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_ebottom, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  call h5dopen_f(file_id, "bin_top", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_etop, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  allocate(nulibtable_logrho(nulibtable_nrho))
  allocate(nulibtable_logtemp(nulibtable_ntemp))
  allocate(nulibtable_ye(nulibtable_nye))
    
  rank = 1
  dims1(1) = nulibtable_nrho
  call h5dopen_f(file_id, "rho_points", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_logrho, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error     

  rank = 1
  dims1(1) = nulibtable_ntemp
  call h5dopen_f(file_id, "temp_points", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_logtemp, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error  

  rank = 1
  dims1(1) = nulibtable_nye
  call h5dopen_f(file_id, "ye_points", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_ye, dims1, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  nulibtable_logrho = log10(nulibtable_logrho)
  nulibtable_logrho_min = nulibtable_logrho(1)
  nulibtable_logrho_max = nulibtable_logrho(nulibtable_nrho)
  nulibtable_logtemp = log10(nulibtable_logtemp) 
  nulibtable_logtemp_min = nulibtable_logtemp(1)
  nulibtable_logtemp_max = nulibtable_logtemp(nulibtable_ntemp)
  nulibtable_ye_min = nulibtable_ye(1)
  nulibtable_ye_max = nulibtable_ye(nulibtable_nye)
  
  !now read three tables
  rank = 5
  dims5(1) = nulibtable_nrho
  dims5(2) = nulibtable_ntemp
  dims5(3) = nulibtable_nye
  dims5(4) = nulibtable_number_species  
  dims5(5) = nulibtable_number_groups  


  allocate(nulibtable_temp(nulibtable_nrho,nulibtable_ntemp, &
       nulibtable_nye,nulibtable_number_species,nulibtable_number_groups))  
  allocate(nulibtable_emissivities(nulibtable_nrho,nulibtable_ntemp, &
       nulibtable_nye,nulibtable_number_species*nulibtable_number_groups))
  allocate(nulibtable_absopacity(nulibtable_nrho,nulibtable_ntemp, &
       nulibtable_nye,nulibtable_number_species*nulibtable_number_groups))
  allocate(nulibtable_scatopacity(nulibtable_nrho,nulibtable_ntemp, &
       nulibtable_nye,nulibtable_number_species*nulibtable_number_groups))

  call h5dopen_f(file_id, "emissivities", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp, dims5, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  do i=1,nulibtable_number_species
     startindex = (i-1)*nulibtable_number_groups+1
     endindex = startindex + nulibtable_number_groups - 1
     do j = 1,nulibtable_number_groups
        nulibtable_emissivities(:,:,:,startindex+j-1) = log10(max(1.0d-60,&
             nulibtable_temp(:,:,:,i,j)*nulibtable_ewidths(j)))
     enddo
  enddo

  call h5dopen_f(file_id, "absorption_opacity",dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp, dims5, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  do i=1,nulibtable_number_species
     startindex = (i-1)*nulibtable_number_groups+1
     endindex = startindex + nulibtable_number_groups - 1
     nulibtable_absopacity(:,:,:,startindex:endindex) = log10(nulibtable_temp(:,:,:,i,:))
  enddo

  call h5dopen_f(file_id, "scattering_opacity", dset_id, error)
  call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp, dims5, error)
  call h5dclose_f(dset_id, error)
  cerror = cerror + error   

  do i=1,nulibtable_number_species
     startindex = (i-1)*nulibtable_number_groups+1
     endindex = startindex + nulibtable_number_groups - 1
     nulibtable_scatopacity(:,:,:,startindex:endindex) = log10(nulibtable_temp(:,:,:,i,:))
  enddo

  deallocate(nulibtable_temp)

  nulibtable_number_easvariables = 3

  if (include_Ielectron.or.include_epannihil_kernels.or.include_bremsstrahlung_kernels&
		.or.include_gang_kernels) then

     !read scalars (rank=1, dims1(1) = 1)
     rank = 1
     dims1(1) = 1
     
     call h5dopen_f(file_id, "Itemp",dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_nItemp, dims1, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error
     
     call h5dopen_f(file_id, "Ieta",dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_nIeta, dims1, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error
     
     call h5dopen_f(file_id, "In_N",dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_nn_N, dims1, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error
     
    if (include_gang_kernels) then
        call h5dopen_f(file_id, "IYe",dset_id, error)
        call h5dread_f(dset_id, H5T_NATIVE_INTEGER, nulibtable_nIYe, dims1, error)
        call h5dclose_f(dset_id, error)
        cerror = cerror + error
    endif

     allocate(nulibtable_logItemp(nulibtable_nItemp))
     allocate(nulibtable_logIeta(nulibtable_nIeta))
     allocate(nulibtable_logn_N(nulibtable_nn_N))
     allocate(nulibtable_logYe(nulibtable_nIYe))

     rank = 1
     dims1(1) = nulibtable_nItemp
     call h5dopen_f(file_id, "temp_Ipoints", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_logItemp, dims1, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error  

     rank = 1
     dims1(1) = nulibtable_nIeta
     call h5dopen_f(file_id, "eta_Ipoints", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_logIeta, dims1, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error
     write(*,*) MAXVAL(nulibtable_logIeta)
     
     if (include_bremsstrahlung_kernels .or. include_gang_kernels) then 
	     rank = 1
	     dims1(1) = nulibtable_nn_N
	     call h5dopen_f(file_id, "n_N_Ipoints", dset_id, error)
	     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_logn_N, dims1, error)
	     call h5dclose_f(dset_id, error)
	     cerror = cerror + error
	 endif
     if (include_gang_kernels) then 
	     rank = 1
	     dims1(1) = nulibtable_nIYe
	     call h5dopen_f(file_id, "Ye_Ipoints", dset_id, error)
	     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_logYe, dims1, error)
	     call h5dclose_f(dset_id, error)
	     cerror = cerror + error
	 endif
	 
     nulibtable_logItemp = log10(nulibtable_logItemp) 
     nulibtable_logItemp_min = nulibtable_logItemp(1)
     nulibtable_logItemp_max = nulibtable_logItemp(nulibtable_nItemp)
     nulibtable_logIeta = log10(nulibtable_logIeta) 
     nulibtable_logIeta_min = nulibtable_logIeta(1)
     nulibtable_logIeta_max = nulibtable_logIeta(nulibtable_nIeta)
     
     if (include_bremsstrahlung_kernels .or. include_gang_kernels) then 
	     nulibtable_logn_N = log10(nulibtable_logn_N) 
	     nulibtable_logn_N_min = nulibtable_logn_N(1)
	     nulibtable_logn_N_max = nulibtable_logn_N(nulibtable_nn_N)
     endif
     
     if (include_bremsstrahlung_kernels .or. include_gang_kernels) then 
		 nulibtable_logYe = log10(nulibtable_logYe) 
	     nulibtable_logYe_min = nulibtable_logYe(1)
	     nulibtable_logYe_max = nulibtable_logYe(nulibtable_nIYe)
     endif
     
     
     
  endif

  if (include_Ielectron) then

     rank = 5
     dims5(1) = nulibtable_nItemp
     dims5(2) = nulibtable_nIeta
     dims5(3) = nulibtable_number_groups
     dims5(4) = nulibtable_number_species
     dims5(5) = nulibtable_number_groups

     if (dims5(3).ne.dims5(5)) stop "Inelastic must be square"

     allocate(nulibtable_temp(dims5(1),dims5(2),dims5(3),dims5(4),dims5(5)))
     allocate(nulibtable_Itable_Phi0(dims5(1),dims5(2),dims5(4)*dims5(3)*(dims5(3)+1)/2))
     allocate(nulibtable_Itable_Phi1(dims5(1),dims5(2),dims5(4)*dims5(3)*(dims5(3)+1)/2))

     call h5dopen_f(file_id, "inelastic_phi0", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp, dims5, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error   

     index = 0
     do i=1,nulibtable_number_species !species
        do j=1,nulibtable_number_groups !incoming E
           do k=1,j !outgoing E
              index = index + 1
              nulibtable_Itable_Phi0(:,:,index) = log10(max(1.0d-200,nulibtable_temp(:,:,j,i,k)))
           enddo
        enddo
     enddo

     call h5dopen_f(file_id, "inelastic_phi1", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp, dims5, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error   

     index = 0
     do i=1,nulibtable_number_species !species
        do j=1,nulibtable_number_groups !incoming E
           do k=1,j !outgoing E
              index = index + 1
              nulibtable_Itable_Phi1(:,:,index) = nulibtable_temp(:,:,j,i,k)/ &
                   10.0d0**nulibtable_Itable_Phi0(:,:,index)
           enddo
        enddo
     enddo

     deallocate(nulibtable_temp)
     
  endif

  if (include_epannihil_kernels) then
     rank = 6
     dims6(1) = nulibtable_nItemp
     dims6(2) = nulibtable_nIeta
     dims6(3) = nulibtable_number_groups
     dims6(4) = nulibtable_number_species
     dims6(5) = nulibtable_number_groups
     dims6(6) = 2

     if (dims6(3).ne.dims6(5)) stop "epannihil kernels must be square"

     allocate(nulibtable_temp2(dims6(1),dims6(2),dims6(3),dims6(4),dims6(5),dims6(6)))
     allocate(nulibtable_epannihiltable_Phi0(dims6(1),dims6(2),dims6(4)*dims6(3)*dims6(3)*2))
     allocate(nulibtable_epannihiltable_Phi1(dims6(1),dims6(2),dims6(4)*dims6(3)*dims6(3)*2))

     call h5dopen_f(file_id, "epannihil_phi0", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp2, dims6, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error   

     index = 0
     do i=1,nulibtable_number_species !species
        do j=1,nulibtable_number_groups !neutrino E
           do k=1,nulibtable_number_groups !otherne E
              index = index + 1
              nulibtable_epannihiltable_Phi0(:,:,index) = log10(max(1.0d-200,nulibtable_temp2(:,:,j,i,k,1)))
              index = index + 1
              nulibtable_epannihiltable_Phi0(:,:,index) = log10(max(1.0d-200,nulibtable_temp2(:,:,j,i,k,2)))
           enddo
        enddo
     enddo

     call h5dopen_f(file_id, "epannihil_phi1", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp2, dims6, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error   

     index = 0
     do i=1,nulibtable_number_species !species
        do j=1,nulibtable_number_groups !neutrino E
           do k=1,nulibtable_number_groups !othernu E
              index = index + 1
              nulibtable_epannihiltable_Phi1(:,:,index) = nulibtable_temp2(:,:,j,i,k,1)/ &
                   10.0d0**nulibtable_epannihiltable_Phi0(:,:,index)
              index = index + 1
              nulibtable_epannihiltable_Phi1(:,:,index) = nulibtable_temp2(:,:,j,i,k,2)/ &
                   10.0d0**nulibtable_epannihiltable_Phi0(:,:,index)
           enddo
        enddo
     enddo

     deallocate(nulibtable_temp2)

  endif
  
  
  if (include_bremsstrahlung_kernels) then

     rank = 6
     dims6(1) = nulibtable_nItemp
     dims6(2) = nulibtable_nn_N
     dims6(3) = nulibtable_number_groups
     dims6(4) = nulibtable_number_species
     dims6(5) = nulibtable_number_groups
     dims6(6) = 2
     write(*,*) "brem dim",dims6(1),dims6(2)
     if (dims6(3).ne.dims6(5)) stop "bremsstrahlung kernels must be square"

     allocate(nulibtable_temp2(dims6(1),dims6(2),dims6(3),dims6(4),dims6(5),dims6(6)))
     allocate(nulibtable_bremsstrahlung_Phi0(dims6(1),dims6(2),dims6(4)*dims6(3)*dims6(3)*2))
     call h5dopen_f(file_id, "bremsstrahlung_phi0", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp2, dims6, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error   

     index = 0
     do i=1,nulibtable_number_species !species
        do j=1,nulibtable_number_groups !neutrino E
           do k=1,nulibtable_number_groups !otherne E
              index = index + 1
              nulibtable_bremsstrahlung_Phi0(:,:,index) = log10(max(1.0d-200,ABS(nulibtable_temp2(:,:,j,i,k,1))))
              index = index + 1
              nulibtable_bremsstrahlung_Phi0(:,:,index) = log10(max(1.0d-200,ABS(nulibtable_temp2(:,:,j,i,k,2))))
           enddo
        enddo
     enddo
!~     write(*,*) MAXVAL(nulibtable_bremsstrahlung_Phi0)


     deallocate(nulibtable_temp2)

  endif


  if (include_gang_kernels) then

     rank = 7
     dims7(1) = nulibtable_nItemp
     dims7(2) = nulibtable_nn_N
     dims7(3) = nulibtable_nIYe
     dims7(4) = nulibtable_number_groups
     dims7(5) = nulibtable_number_species
     dims7(6) = nulibtable_number_groups
     dims7(7) = 2
!~      write(*,*) "brem dim",dims6(1),dims6(2)
     if (dims7(4).ne.dims7(6)) stop "bremsstrahlung kernels must be square"

     allocate(nulibtable_temp3(dims7(1),dims7(2),dims7(3),dims7(4),dims7(5),dims7(6),dims7(7)))
     allocate(nulibtable_bremsstrahlung_gang_Phi0(dims7(1),dims7(2),dims7(3),dims7(5)*dims7(4)*dims7(4)*2))
     call h5dopen_f(file_id, "bremsstrahlung_phi0_gang", dset_id, error)
     call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,nulibtable_temp3, dims7, error)
     call h5dclose_f(dset_id, error)
     cerror = cerror + error   

     index = 0
     do i=1,nulibtable_number_species !species
        do j=1,nulibtable_number_groups !neutrino E
           do k=1,nulibtable_number_groups !otherne E
              index = index + 1
              nulibtable_bremsstrahlung_gang_Phi0(:,:,:,index) = log10(max(1.0d-200,ABS(nulibtable_temp3(:,:,:,j,i,k,1))))
              index = index + 1
              nulibtable_bremsstrahlung_gang_Phi0(:,:,:,index) = log10(max(1.0d-200,ABS(nulibtable_temp3(:,:,:,j,i,k,2))))
           enddo
        enddo
     enddo
!~     write(*,*) MAXVAL(nulibtable_bremsstrahlung_Phi0)


     deallocate(nulibtable_temp3)

  endif




  !must close h5 files, check for error
  if (cerror.ne.0) then
     write (*,*) "We have errors on reading HDF5 file", cerror
     stop
  endif  

  call h5fclose_f(file_id,error)
  call h5close_f(error)

!~   if ( include_gang_kernels) then 
!~   !open HDF5 file, given filename                                                                                             
!~ 	  call h5open_f(error)
!~ 	  if (error.ne.0) then
!~ 	     stop "Error reading in gang file"
!~ 	  endif
	  
!~ 	  call h5fopen_f(trim(adjustl("Data.h5")), &
!~ 	       H5F_ACC_RDONLY_F,file_id,error)
!~ 	  if (error.ne.0) then
!~ 	     write(*,*) trim(adjustl("Data.h5"))
!~ 	     stop "Error reading in gang table"
!~ 	  endif
	  
!~ 	rank = 4
!~ 	dims4(1) = 25
!~ 	dims4(2) = 37
!~ 	dims4(3) = 26
!~ 	dims4(4) = 40
!~ 	allocate(gang_table(dims4(1),dims4(2),dims4(3),dims4(4)))
!~ 	call h5dopen_f(file_id, "kernel", dset_id, error)
!~ 	call h5dread_f(dset_id, H5T_NATIVE_DOUBLE,gang_table, dims4, error)
!~     call h5dclose_f(dset_id, error)
!~     cerror = cerror + error   

!~ 	if (cerror.ne.0) then
!~ 	     write (*,*) "We have errors on reading Gang file", cerror
!~ 	     stop
!~ 	endif  
	
!~ 	call h5fclose_f(file_id,error)
!~ 	call h5close_f(error)

!~   endif
  
end subroutine nulibtable_reader
