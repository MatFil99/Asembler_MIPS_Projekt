	.data

newline:			.asciiz "\n"
file:			.asciiz "Julia.bmp"	# nazwa pliku
err_file:		.asciiz "Blad!\nbrak pliku lub niewlasciwy plik"	# gdy brak pliku
string_error_incor_nr:	.asciiz "\nPodano bledna liczbe\n"
string_welcome:		.asciiz "Program tworzacy zbior Julii"
string_instr:		.asciiz "Podaj stala c z zakresu <-3,3> ( z dokladnoscia do czesci 10-cio tysiecznych,\ndla ktorej bedzie generowany zbior Julii (liczba zespolona)\nczesc rzeczywista: "
string_instr2:		.asciiz "czesc urojona: "


bmpHeader:		.space 55

			.align 2
width:			.space 4
height:			.space 4
start_Re:		.space 4	# brzegi ukladu R^2
start_Im:		.space 4
			.align 0


Re_c_string:		.space 8
Im_c_string:		.space 8
			.align 1
Re_c:			.space 2
Im_c:			.space 2

			.align 0
line_of_bitmap:		.space 5000	# bufor do zapisania wartosci pixeli (1 wiersz, 900px * 3 B/pix)

	.text
	.globl main

main:
	
	# welcome
	la	$a0, string_welcome
	li	$v0, 4
	#syscall
	
	# otwarcie pliku Julia.bmp (sprawdzenie czy jest w porzadku)
	
	li	$v0, 13
	la	$a0, file
	li	$a1, 0
	li	$a2, 0
	syscall
	blt	$v0, 0, end_err_file
	move	$s6, $v0
	# wczytanie naglowka z pliku Julia.bmp
	li	$v0, 14
	move	$a0, $s6
	la	$a1, bmpHeader
	li	$a2, 54
	syscall
	
	li	$s0, 0		# licznik (rozpoznanie czy wczytujemy szerokosc , czy wysokosc)
	la	$t0, bmpHeader	# t0 to poczatek naglowka
	addiu	$t0, $t0, 18
	
load_w_h:
	# wczyatnie szerokosci i wysokosci
	li	$t2, 0
	lbu	$t1, ($t0)
	addu	$t2, $t2, $t1
	lbu	$t1, 1($t0)
	mulu	$t1, $t1, 256
	addu	$t2, $t2, $t1
	lbu	$t1, 2($t0)
	mulu	$t1, $t1, 65536
	addu	$t2, $t2, $t1
	lbu	$t1, 3($t0)
	mulu	$t1, $t1, 16777216
	addu	$t2, $t2, $t1

	bnez	$s0, save_height

save_width:	# zapisz szerokosc w pamieci
	la	$s1, width
	sw	$t2, ($s1)
	addiu	$s0, $s0, 1
	addiu	$t0, $t0, 4	# height zaczyna sie od 22 bajtu
	b	load_w_h
save_height:
	la	$s1,height
	sw	$t2, ($s1)
			
	li	$v0, 16
	move	$a0, $s6
	syscall			#zamkniecie pliku Julia.bmp
			
	
	# insrukcja dla uzytkownika
	la	$a0, string_instr
	li	$v0, 4
	syscall
	
	la	$t3, Re_c_string
load_c:		# wczytanie stalej c = a + b*j
	
	la	$a0, Re_c_string
	li	$a1, 7
	li	$v0, 8
	syscall
	la	$a0, string_instr2
	li	$v0, 4
	syscall
	la	$a0, Im_c_string
	li	$a1, 7
	li	$v0, 8
	syscall
	
	li	$t0, 0
	la	$a0, Re_c_string
if_correct_numbers:	# sprawdzenie poprawnosci wprowadzonych liczb
	lb	$a1, ($a0)
	bne	$a1, '-', if_c_n_next
	li	$t1, 1		# zapamietaj znak '-' w rejestrze t1
	addi	$a0, $a0, 1
	lb	$a1, ($a0)
if_c_n_next:
	blt	$a1, '0', incorrect_number
	bgt	$a1, '2', incorrect_number
	addi	$a0, $a0, 1
	lb	$a1, ($a0)
	bne	$a1, '.', incorrect_number
	addi	$a0, $a0, 1
if_c_loop:
	lb	$a1, ($a0)
	ble	$a1, ' ', incr_loop	# sprawdz jeszcze druga liczbe!
	blt	$a1, '0', incorrect_number
	bgt	$a1, '9', incorrect_number
	addi	$a0, $a0, 1
	b	if_c_loop

incorrect_number:
	addi	$a0, $a0, 1
	ble	$a1, ' ', if_c_loop
	la	$a0, string_error_incor_nr
	li	$v0, 4
	syscall
	b	end
incr_loop:
	addi	$t0, $t0, 1
	la	$a0, Im_c_string
	bne	$t0, 1, start_convert_c
	move	$s0, $t1		# znak czesci rzeczywistej
	li	$t1, 0
	b	if_correct_numbers
start_convert_c:
	move	$s1, $t1		# znak czesci urojonej	
	
	li	$a2, 0
convert_c:
	li	$a3, 10000	# licznik wagowy
	li	$t0, 0		# licznik wykonanych petli convert_loop
	la	$a0, Re_c_string
convert_loop:
	lb	$a1, ($a0)
	blt	$a1, ' ', if_second_loop
	blt	$a1, 47, incr 			# nie liczba
	bgt	$a1, 58, incr			# nie liczba
	subi	$a1, $a1, 48
	mul	$a1, $a1, $a3
	add	$a2, $a2, $a1 # dodaj
	addi	$a0, $a0, 1
	div	$a3, $a3, 10
	b	convert_loop

incr:
	addi	$a0, $a0, 1
	b	convert_loop
if_second_loop:
	addi	$t0, $t0, 1
	la	$a0, Im_c_string
	move	$t3, $a0
	bne	$t0, 1, update_sign_Re	# jesli licznik jest rowny 1, to zamienilismy dopiero czesc Re
	li	$a3, 10000		# reset licznika wag
	move	$t4, $a2		# t4 zawiera jedna z liczb
	li	$a2, 0			# reset akumulatora sumujacego
	b	convert_loop
	
update_sign_Re:
	bne	$s0, 1, update_sign_Im
	neg	$t4, $t4
	
update_sign_Im:
	bne	$s1, 1, check_numbers
	neg	$a2, $a2
check_numbers:
	
	sh	$t4, Re_c
	sh	$a2, Im_c
	
	
	
			# wczytano stalą c		
				# otwarcie pliku do zapisu bitmapy
open_file:
	li	$v0, 13
	la	$a0, file	# wczytanie nazwy pliku do otwarcia
	li	$a1, 1		# flags 0: read, 1: write - plik do zapisywania danych
	li	$a2, 0		# mode is ignored
	syscall
	move	$s7, $v0	# skopiowanie file descriptor

# Write to file just opened

write_header:
  	li	$v0, 15       # system call for write to file
	move	$a0, $s7      # file descriptor 
  	la	$a1, bmpHeader
  	li	$a2, 54
  	syscall			# zapisano naglowek pliku BMP
  				
  		
  				# poczatek obliczen zbioru Julii
  				
count_length_per_pixel:		# t7 zawiera dlugosc odpowiadajaca pixelowi
	lw	$s0, width	# szerokosc obrazka
	lw	$s1, height	# wysokosc obrazka
	li	$t7, 30000
	blt	$s0, $s1, set_w_h
				# wysokosc jest mniejsza, wiec wysokosc skalujemy do 3 jednostek
	divu	$t7, $t7, $s1	# t7 przesuniecie ( liczba jednostek przypadajacych na pixel )
	li	$s4, -14960	# dolna granica Im
	mul	$s6, $s1, $t7	
	add	$s6, $s6, $s4	# gorna granica Im
	mul	$s3, $s0, $t7
	sra	$s3, $s3, 1
	neg	$s3, $s3	# dolna granica Re
	mul	$s5, $t7, $s0
	add	$s5, $s5, $s3	# gorna granica Re
	add	$s3, $s3, $t7
	b	count_align

set_w_h:	# ustawia standardowo poczatkowa wartosc rzeczywista
	divu	$t7, $t7, $s0
	li	$s3, -14960	# dolna granica Re
	mul	$s5, $s0, $t7	
	add	$s5, $s5, $s3	# gorna granica Im
	mul	$s4, $s1, $t7
	sra	$s4, $s4, 1
	neg	$s4, $s4	# dolna granica Im
	mul	$s6, $t7, $s1
	add	$s6, $s6, $s4	# gorna granica Im
	add	$s4, $s4, $t7
	
count_align:			# przeliczone wyrownanie bitmapy w s5
	sw	$s3, start_Re	# brzeg przestrzeni R^2	(lewy dolny)
	sw	$s4, start_Im
	
	move	$t6, $s0
	sll	$t6, $t6, 1
	add	$t6, $t6, $s0
	sra	$t4, $t6, 2	# tymczasowo przechowujemy w t4 liczbe t6/4
	sll	$t4, $t4, 2
	sub	$t6, $t6, $t4
	li	$t4, 4
	subu	$t6, $t4, $t6
	bne	$t6, 4, write_bitmap
	li	$t6, 0
	


write_bitmap:
	lh	$t8, Re_c	# stala c = a + bj
	lh	$t9, Im_c
	move	$t0, $s3	# czesc Re punktu
	move	$t1, $s4	# czesc Im punktu
	move	$t2, $t0	# czesc Re n-tego wyrazu
	move	$t3, $t1	# czesc Im n-tego wyrazu
	li	$a1, 0		# licznik wyrazu ciagu
	la	$s2, line_of_bitmap	# wskaznik na miejsce do przechowania jednego wiersza bitmapy
	
do_bitmap:
	mul	$t4, $t2, $t2
	div	$t4, $t4, 10000
	mul	$t5, $t3, $t3
	div	$t5, $t5, 10000
	sub	$t4, $t4, $t5
	mul	$t5, $t2, $t3
	div	$t5, $t5, 10000
	sll	$t5, $t5, 1
	add	$t2, $t4, $t8
	add	$t3, $t5, $t9
	mul	$t4, $t2, $t2
	div	$t4, $t4, 10000
	mul	$t5, $t3, $t3
	div	$t5, $t5, 10000
	add	$t4, $t4, $t5
	bgt	$t4, 40000, bad_point
	add	$a1, $a1, 1
	ble	$a1, 20, do_bitmap
	
	# dobry punkt
	
	li	$t4, 0
	sb	$t4, ($s2)
	sb	$t4, 1($s2)
	li	$t4, 55
	sb	$t4, 2($s2)
	b	incr_point_Re

bad_point:
	li	$t4, 255
	sb	$t4, ($s2)
	sb	$t4, 1($s2)
	sb	$t4, 2($s2)
	
incr_point_Re:
	add	$s2, $s2, 3
	add	$t0, $t0, $t7
	bgt	$t0, $s5, align_verse
	move	$t2, $t0
	move	$t3, $t1
	li	$a1, 0
	b	do_bitmap
align_verse:
	li	$a1, 0
	sb	$a1, ($s2)
	sb	$a1, 1($s2)
	sb	$a1, 2($s2)
incr_point_Im:
	add	$t1, $t1, $t7
	move	$t4, $s0
	sll	$t4, $t4, 1
	add	$t4, $t4, $s0	# t4 * 3
	add	$t4, $t4, $t6	# t4 + wyrownanie
	
	li	$v0, 15
	la	$a1, line_of_bitmap
	move	$a0, $s7
	move	$a2, $t4
	syscall
	move	$s2, $a1
	move	$t0, $s3
	move	$t2, $t0
	move	$t3, $t1
	li	$a1, 0
	ble	$t1, $s6, do_bitmap
	
	
	
	
	
	
	
  	


# -  -  -  -  =   = = = = = = = = =  = = = = = =  = = = =



	
close_file:
  	li   	$v0, 16       # system call for close file
  	move	$a0, $s7      # file descriptor to close
  	syscall            # close file
	b end
	
end_err_file:
	li	$v0, 4
	la	$a0, err_file
	syscall

end:

	li	$v0, 10
	syscall
