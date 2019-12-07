	.data

newline:		.asciiz "\n"
file:			.asciiz "Julia.bmp"	# nazwa pliku
err_file:		.asciiz "Blad!\nbrak pliku lub niewlasciwy plik"	# gdy brak pliku
string_error_incor_nr:	.asciiz "\nPodano bledna liczbe\n"
string_welcome:		.asciiz "Program tworzacy zbior Julii"
string_instr:		.asciiz "Podaj liczbe z zakresu <-32768; 32767) odpowiadajaca stala c z zakresu <-2,2) \ndla ktorej bedzie generowany zbior Julii (liczba zespolona)\n czesc rzeczywista: "
string_instr2:		.asciiz " czesc urojona: "

bmpHeader:		.space 55			
			.align 2
width:			.space 4
height:			.space 4
start_Re:		.space 4	# brzegi ukladu R^2
start_Im:		.space 4
pos_bitmap:		.space 4
			.align 0
Re_c_string:		.space 8
Im_c_string:		.space 8
			.align 1
Re_c:			.space 2
Im_c:			.space 2

			.align 0
line_of_bitmap:		.space 2432701	# bufor do zapisania wartosci pixeli (1 wiersz, 900px * 3 B/pix)

	.text
	.globl main

main:
	
	# welcome
	la	$a0, string_welcome
	li	$v0, 4
	syscall
	
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
	#sll	$t2, $t2, 14	# konwersja na liczbe na ktorej bedziemy operowac
	sw	$t2, ($s1)
	addiu	$s0, $s0, 1
	addiu	$t0, $t0, 4	# height zaczyna sie od 22 bajtu
	b	load_w_h
save_height:
	la	$s1,height
	#sll	$t2, $t2, 14
	sw	$t2, ($s1)
			
	li	$v0, 16
	move	$a0, $s6
	syscall			#zamkniecie pliku Julia.bmp
	
load_c:
	li	$v0, 4
	la	$a0, string_instr
	syscall
	
	li	$v0, 5
	syscall
	bgt	$v0, 32767, err_c
	sh	$v0, Re_c
	blt	$v0, -32768, err_c
	li	$v0, 4
	la	$a0, string_instr2
	syscall				# instrukcja dla uzytkownika
	li	$v0, 5
	syscall
	bgt	$v0, 32767, err_c
	sh	$v0, Im_c
	blt	$v0, -32768, err_c

		# wczytano stala C
		
open_file:
	li	$v0, 13
	la	$a0, file	# wczytanie nazwy pliku do otwarcia
	li	$a1, 1		# flags 0: read, 1: write - plik do zapisywania danych
	li	$a2, 0		# mode is ignored
	syscall
	move	$s7, $v0	# skopiowanie file descriptor

write_header:
  	li	$v0, 15       # system call for write to file
	move	$a0, $s7      # file descriptor 
  	la	$a1, bmpHeader
  	li	$a2, 54
  	syscall			# zapisano naglowek pliku BMP
	
	la	$t7, line_of_bitmap
	sw	$t7, pos_bitmap

			# poczatek obliczen zbioru Julii

count_length_per_pixel:		# t7 zawiera dlugosc odpowiadajaca pixelowi
	lw	$s0, width	# szerokosc obrazka
	lw	$s1, height	# wysokosc obrazka
	li	$t7, 49152	# plaszczyzna zespolona wymiary: 3 x wys lub szer x 3
	blt	$s0, $s1, set_w_h
	
	
				# wysokosc jest mniejsza, wiec wysokosc skalujemy do 3 jednostek
	divu	$t7, $t7, $s1	# t7 przesuniecie ( liczba jednostek przypadajacych na pixel )\
	li	$s4, -24510	# dolna granica Im okolo -1.496
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
	li	$s3, -24510	# dolna granica Re
	mul	$s5, $s0, $t7	
	add	$s5, $s5, $s3	# gorna granica Im
	mul	$s4, $s1, $t7
	sra	$s4, $s4, 1
	neg	$s4, $s4	# dolna granica Im
	mul	$s6, $t7, $s1
	add	$s6, $s6, $s4	# gorna granica Im
	add	$s4, $s4, $t7

count_align:			# przeliczone wyrownanie bitmapy w t6
	sw	$s3, start_Re	# brzeg przestrzeni R^2	(lewy dolny)
	sw	$s4, start_Im
	
	move	$t6, $s0
	sll	$t6, $t6, 1
	add	$t6, $t6, $s0	# przemnozenie przez 3 (3*s0)
	sra	$t4, $t6, 2	# tymczasowo przechowujemy w t4 liczbe t6/4
	sll	$t4, $t4, 2
	sub	$t6, $t6, $t4
	li	$t4, 4
	subu	$t6, $t4, $t6	# reszta z dzielenia t6 / 4
	bne	$t6, 4, write_bitmap
	li	$t6, 0

		# poczatek obliczen zbioru Julii
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
	sra	$t4, $t4, 14
	mul	$t5, $t3, $t3
	sra	$t5, $t5, 14
	sub	$t4, $t4, $t5
	mul	$t5, $t2, $t3
	sra	$t5, $t5, 14
	sll	$t5, $t5, 1
	add	$t2, $t4, $t8
	add	$t3, $t5, $t9
	mul	$t4, $t2, $t2
	sra	$t4, $t4, 14
	mul	$t5, $t3, $t3
	sra	$t5, $t5, 14
	add	$t4, $t4, $t5
	bgt	$t4, 65536, bad_point
	add	$a1, $a1, 1
	ble	$a1, 10, do_bitmap	# dokladnosc ( nr wyrazu )
	
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
		
		# wersja z wczytywaniem do pliku po linii pixeli
	#move	$t4, $s0
	#sll	$t4, $t4, 1
	#add	$t4, $t4, $s0	# t4 * 3
	#add	$t4, $t4, $t6	# t4 + wyrownanie
	#li	$v0, 15
	#la	$a1, line_of_bitmap
	#move	$a0, $s7
	#move	$a2, $t4
	#syscall
	#move	$s2, $a1
	#add	$s2, $s2, $t6	# s2 + wyrownanie
	
	move	$t0, $s3
	move	$t2, $t0
	move	$t3, $t1
	li	$a1, 0
	ble	$t1, $s6, do_bitmap
	
make_bitmap_AND_close_file:
		# wersja z wpisywaniem do pliku calego bufora obrazka
	mul	$t4, $s0, $s1	# szerokosc * wysokosc
	mulu	$t4, $t4, 3	# * 3
	mul	$t6, $t6, $s1	# wyrównanie * wysokosc
	add	$t4, $t4, $t6
	li	$v0, 15
	la	$a1, line_of_bitmap
	move	$a0, $s7
	move	$a2, $t4
	syscall

  	li   	$v0, 16       # system call for close file
  	move	$a0, $s7      # file descriptor to close
  	syscall            # close file
	b end

err_c:
	li	$v0, 4
	la	$a0, string_error_incor_nr
	syscall
	b	end

end_err_file:
	li	$v0, 4
	la	$a0, err_file
	syscall

end:

	li	$v0, 10
	syscall
