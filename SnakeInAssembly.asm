;@2018
;Author:    -Achmad Kripton Nugraha (Teknik Komputer - A - 1606828085)
;           -Athina Maria Angelica  (Teknik Komputer - A - 1606887024)
;           -Aria Lesmana           (Teknik Komputer - A - 1506732690)
;           -Cakti Fadillah         (Teknik Komputer - A - 1606890113)
;           -Mifta Adiwira          (Teknik Komputer - A - 1406567403)
;Kelompok: A
;Skenario:
;       -User memberikan input W, A, S, D untuk mengatur arah gerak ular
;       -Ular akan bertambah panjang jika melewati makanan
;       -Ular akan mati jika memakan ekor sendiri atau Ranjau
;       -User dapat menekan q untuk ke main menunya lagi

;Copyright 2018 Kelompok A Proyek UTS Praktikum Sistem Berbasis Komputer
;Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
;(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
;distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the 
;following conditions:
;The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
;MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
;CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
;SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;referensi:
;   http://webpages.charter.net/danrollins/techhelp/0089.HTM
;   http://www.computing.dcu.ie/~ray/teaching/CA296/notes/8086_bios_and_dos_interrupts.html 
;   Art of Assembly Language (Intel X86) 

.286
.model small
.stack 0fffH
.data
;berikut adalah variabel untuk mengecek flag keatas,bawah,kanan, kiri,dan mati
nada  dw  0     
BAWAH DB 00h              
ATAS DB 00h
KANAN DB 01h
KIRI DB 00h
BERHENTI DB 0 
MATI DB 0
waktu_var dw 2
;akhir dari variabel flag
tulisan_mati db 'Anda telah mati',0ah,0DH,'Press Any key to continue...$'                          ;tulisan untuk dicetak saat mati
tulisanskor db 'Score: $'                                   ;tulisan untuk dicetak di bagian atas untuk Score
tulisan db 'Tekan q untuk ke main menu                $'    ;tulisan dicetak dibagian atas untuk membeeri tahu user cara ke main menu

menu DB "Snake Game",0AH,0DH,"Masukkan pilihan berupa angka yang diinginkan",0AH,0DH,"1.Main",0AH,0DH,"2.Keluar",0AH,0DH,"$"
instruksi DB "Mengendalikan ular",0AH,0DH,"W:Atas, A:Kiri, S:Bawah, D:Kanan",0AH,0DH,"Kepala:",0010H,", Ekor:",0FEH,", Makanan:",015H,", Ranjau: X",0AH,0DH,"Kembali ke menu : Q",0AH,0DH,"Press Any Key to continue$"
psnexit DB "Terimakasih sudah bermain",0DH,0AH,"$"

SKOR DW 0           ;variabel untuk menyimpan skor yang dimiliki
CNT_SKOR DB 0       ;variabel untuk menampung dijit SKOR
BARIS_NOW DB 0      ;variable untuk menyimpan posisi baris dari ular
KOLOM_NOW DB 0      ;variabel untuk menyimpan posisi kolom dari ular
TARGET_GESER_BARIS DB 0 ;variabel untuk menyimpan 
TARGET_GESER_KOLOM DB 1

offset_atas equ 1
GAMBAR_HEAD DW 0B410H       ; gambar kepala
GAMBAR_EKOR EQU 0A4FEH      ; gambar ekor
food_pic dw 0cd15h          ;gambar makanan
bomb_pic dw 03c78h          ;gambar bomb

MIN_ROW EQU 0               ; baris minimum
MIN_COL EQU 0               ;kolom minimun
MAX_ROW EQU 24-offset_atas  ;maximum baris, yaitu 24-offset_atas. 24 didapatkan dari perhitungan layarnya 80*25. (karena 0-24)
MAX_COL EQU 79              ;kolom maksimum, yaitu 79 offset. Didapatkan dari hitungan layar 80*25 (karena 0-79)
max_bod equ 100             ; deklarasi maksimum panjangnya adalah 100
empty_pixel equ 0000h       ;sebagai pixel kosong untuk ditulis ke memori
CURRENT_KURSOR_KEPALA dw 0000h  ;posisi kursor kepala, lebih tepat alamatnya

USER_INPUT DB 0             ;sebagai flag apakah ada input atau tidak
WAKTU DB 2                 ;untuk pewaktuan

bod_size db 1               ;inisialisasi ukuran badan awalnya sebesar 1
en_bomb db 1                ;flag untuk menyalakan bomb
food dw 10h                 ;untuk alamat food
bomb dw 20h                 ;untuk alamat bomb
CURRENT_HEAD DW max_bod dup (0h)      ;menyimpan posisi kursor sekarang, high byte baris, low byte kolom

.code 


delay_not proc            ; Pengaturan jeda antar not
    MOV     CX, 01H
    MOV     DX, 120H
    MOV     AH, 86H
    INT     15H 
    ret    
    endp
                

; Pengaturan setiap nada yang digunakan 
do proc             
        mov     ax, 4560
        mov     nada, ax
        call    sounder         
        endp   
        ret
re proc
        mov     ax, 4063
        mov     nada, ax
        call    sounder       
        ret 
        endp
mi proc
        mov     ax, 3619
        mov     nada, ax
        call    sounder         
        ret 
        endp   
fa proc
        mov     ax, 3416
        mov     nada, ax
        call    sounder         
        ret
        endp
sol proc
        mov     ax, 3043
        mov     nada, ax
        call    sounder        
        ret
        endp
                    
; pengaturan keluarnya bunyi di speaker 
sounder:                       
        mov     al,10110110b    
        out     43h,al          ; menyalakan port 43
        mov     ax,nada        
        out     42h,al          
        mov     al,ah          
        out     42h,al          
        in      al,61h         
        or      al,00000011b   
        out     61h,al          
        call    delay           
        and     al,11111100b   
        out     61h,al          
        ret                   

;pengaturan waktu saat nada dibunyikan
delay:                          ;delay untuk bunyi suara
        mov     ah,00h          
        int     01Ah           ; single step interrupt           
        add     dx,waktu_var        
        mov     bx,dx         
pozz:
        int     01Ah           
        cmp     dx,bx          
        jl      pozz           
        ret 

init proc near          ;procedur untuk mereset variable ke nilai awal
	pusha
    mov bawah,0
    mov atas, 0
    mov kanan, 01h
    mov kiri, 0
    mov berhenti, 0
    mov mati, 0
    mov skor, 0
    mov baris_now, 0
    mov kolom_now, 0
    mov target_geser_baris,0
    mov target_geser_kolom, 0
    mov current_kursor_kepala,0
    mov user_input, 0
    mov bod_size, 1
    mov cx, max_bod
    mov di, 0
    ulangi_init:
    mov current_head[di],0      ;Kosongkan isi badan ular
    inc di
    inc di
    loop ulangi_init            ;lakukan sebanyak panjang maksimum badannya
	popa
	ret
init endp

special_clrscreen proc near         ;clearscreen except the upper interface
    pusha
    
    mov al, offset_atas         
    mov dl, 160
    mul dl
    mov bx, ax
    ;beginning code to clear any scree except the first row
    mov cx, 1920    ;approximately pixel to clear is 1920pixel
    mov di, 0       ;index to memory video
    gege:
        mov word ptr ES:[bx+di], EMPTY_PIXEL        ;write the memory 0000h to clear it
        INC di                          
        INC di                                      ;increase 2 because it's word
        loop gege                                   ;loop again until screen is cleared  
    ;end of code
    popa
    ret
special_clrscreen endp

tampilkan_score proc near               ;prosedur untuk menampilkan score dan tulisan petunjuk
    pusha                       
    mov ax, 0b800h                      ;make sure es is 0B800H
    mov es, ax
    mov cx, 80                          ;set cx 80, cause it's only need to erase first row
    mov bx, 0000                       ;base address to the interface
    mov di,0
    bersihkan:                          ;this is rutin to clear the upper interface
        mov word ptr es:[bx+di], 0700H  ;write 0700H untuk menghasilkan pixel kosong dan bisa ditulis dengan interrupt lain
        inc di
        inc di
        loop bersihkan
    ;this is rutin to set cursor to first position
    mov dl, 0
    mov dh, 0
    mov ah, 02h                         ;use service 02h
    mov bh, 00h                         ;on page 0
    int 10h
    mov CNT_SKOR, 0                     ;inisialisasi variabel CNT_SKOR bernilai 0
    mov ah, 09h                         
    lea dx, tulisan                     ;cetak tulisan petunjuk keluar program
    int 21h
    mov ah, 09h         
    lea dx, tulisanskor                 ;cetak tulisan score
    int 21h
    mov ax, SKOR                        ;simpan isi score di ax
    mov dl, 10                          ;sebagai pembagi untuk mendapatkan digit dari score
    simpan_stack:                       ;rutin untuk mendapatkan semua digit ke stack
        div dl                          ;bagi skor dengan nilai 10
        INC CNT_SKOR                    ;increment CNT_SKOR untuk menambah digit skor
        mov dh, al                      ;selamatkan hasil bagi ke dh
        mov al, ah                      ;isi al dengan sisa bagi untuk digit terakhir
        mov ah, 00h                     ;isi high byte dengan 0
        or ax, 0030h                    ;or kan untuk mendapatkan nilai ascii
        push ax                         ;simpan nilai ascii ke stack (karena dari LSB dulu)
        mov al, dh                      ;kembalikan hasil bagi ke al
        mov ah, 00h                     ;pastikan ah 0 agar tidak ada masalah
        cmp al, 0                       ;cek apakah hasil bagi 0 atau tidak, jika 0 pasti dia MSB nya sehingga sudah semua digit disimpan di stack
        jne simpan_stack                ;jika sudah sampai msb berhenti dari rutin
    or al,30h                           ;or kan nilai msb agar menjadi ascii
    push ax                             ;masukkan ke stack sehingga stack sudah berisi nilai score dalam ascii dan siap cetak
    INC CNT_SKOR                        ;increment nilai untuk menambah digit karena ada masuk nilai MSB nya
    mov cl, CNT_SKOR                    ;pindahkan panjang digit ke cx untuk looping sebanyak digit
    mov ch, 00h
    ulang_tampil:                       ;rutin untuk menampilkan digit
        pop dx                          ;keluarkan dari MSB ke LSB
        mov ah, 02h                     ;panggil int 21h dengan fungsi 02h untuk mencetak karakter di dl
        int 21h
        loop ulang_tampil               ;lakukan sebanyak jumlah digit
    popa
    ret
tampilkan_score endp

PERIKSA macro CURVAL, MAXVAL, MINVAL, TARGET_GESER
    local ujung                 ; create local label
    local akhir
    
    pusha         
    mov al , CURVAL
    cmp al, MAXVAL         ;Jika nilai posisi sekarang adalah maksnya, maka dia ada di titik akhir
    je UJUNG                    ;dan harus di geser ke titik awal
    jmp akhir
    
    UJUNG:
        mov al,MINVAL                       ;jika posisi di titik akhir maka, update posisi ke titik awal lagi
        mov TARGET_GESER, al
    
    akhir:
    popa
endm

gen_rand macro which
    local spawn_check
    local retry_spawn

    pusha

    retry_spawn:  

    mov ah, 0h
    int 1ah
    
    mov al, dl      ;for column
    mov ah, 0
    mov cx, MAX_COL
    div cl
    mov dl, ah  	;end column calculation

    push dx  		;save dx

    mov ah, 0h
    int 1ah

    mov al, dl     ;for row
    mov ah, 0
    mov cx, MAX_ROW
    div cl 	       ;end row calculation

    pop dx
    mov dh, ah
    inc dh 			

    mov which, dx

    ;check if collide with bod 
    mov al, bod_size
    mov ah, 0
    mov dl, 2
    mul dl
    mov di,ax
    add di, 2

    spawn_check:
    sub di, 2
    mov dx, current_head[di]
    cmp which, dx
    je retry_spawn
    cmp di, 0
    ja spawn_check

    ;check if food collide with bomb
    mov dx, food
    cmp bomb, dx
    je retry_spawn

    popa
endm

masukan proc near
    pusha
    mov ah, 01h
    int 16h
    jz keluar_bantuan               ; use helper to jump
    mov ah, 00h
    int 16h
    mov USER_INPUT, 1
    mov dl, 1                      
    cmp al, 'w'   ;if w is pressed then go up 
    je masukan_atas   
    cmp al, 'a' ;if a is pressed, go left
    je masukan_kiri
    cmp al, 's' ;if s is pressed, go down
    je masukan_bawah
    cmp al, 'd' ;if a is pressed, go left
    je masukan_kanan
    CMP AL, 'q' ; if q pressed immediately exit
    JE masukan_berhenti_bantuan  
    keluar_bantuan:     ;helper to jump to keluar
    JMP keluar
    
    masukan_atas:
        cmp bawah, 1
        je keluar
        mov bawah,0
        mov kiri,0
        mov kanan, 0
        mov atas, 1
        jmp keluar
    masukan_berhenti_bantuan:       ;this is label to help for jump purpose
        jmp masukan_berhenti
    masukan_bawah:
    cmp atas, 1
        je keluar
        mov atas,0
        mov kiri,0
        mov kanan,0
        mov bawah, 1
        jmp keluar
    masukan_kiri:
    cmp kanan, 1
        je keluar
        mov atas, 0
        mov bawah, 0
        mov kanan,0
        mov kiri,1
        jmp keluar
    masukan_kanan:
    cmp kiri, 1
        je keluar
        mov atas, 0
        mov bawah, 0
        mov kiri,0
        mov kanan, 1
        jmp keluar
    masukan_berhenti:
        mov BERHENTI, 1
        jmp keluar
    keluar: 
    popa
    ret
masukan endp 

delay1 proc 
        
    
    pusha
        
    mov ah, 00
        
    int 1Ah
        
    mov bx, dx
        

    jmp_delay:
    call masukan 			;cek input
    cmp BERHENTI, 1
    je akhir_delay1
    int 1Ah
    sub dx, bx
        
    cmp dl, WAKTU 			;menentukan kecepatan gerak ular                                                      
        
    jl jmp_delay    
    akhir_delay1: 
    popa   
    ret

delay1 endp

 

CLRSCR proc near            ;prosedur untuk membersihkansatu layar full
 pusha          
 mov ah, 00h                
 mov al, 03h                ;jalankan interrupt 10h dengan fungsi 0003h
 int 10h                
 popa
 ret
clrscr endp

update_position proc near
    pusha 

    ;check if collide with food
    mov dx, current_head    
    cmp food, dx
    je yumfood
    cmp bomb, dx        ;check if collide bomb
    je ohnoes_helper           ;you dead    
    jmp nofood
    
    ohnoes_helper:
    jmp ohnoes
    
    yumfood:                ;not collided and eat food
    call do
    call sol
    call delay_not
    gen_rand food
    inc bod_size            ;increase body size
    inc SKOR                ;increase skor
    call tampilkan_score    ;update new skor
    
    back_pls:               ;update bomb and food position
    gen_rand bomb
    jmp cont_pls

    ohnoes:
    inc MATI
    jmp yunojmp

    cont_pls:
    gen_rand food

    nofood:
    mov al, bod_size
    mov ah, 0
    mov cl, 2
    mul cl
    mov bx, ax
    add bx, 2
    
    tails:
    mov cx, current_head[bx-2]
    mov current_head[bx], cx
    sub bx, 2
    cmp bx, 2
    jae tails

    cmp kiri,1
    je kekiri
    cmp kanan,1
    je kekanan
    cmp atas,1
    je keatas
    cmp bawah,1
    je kebawah
    jmp keluar_upda

    kekiri:    
        DEC TARGET_GESER_KOLOM                               ;geser target kekiri
        
        
        periksa KOLOM_NOW,MIN_COL,MAX_COL,TARGET_GESER_KOLOM ;memastikan target didalam area
        mov gambar_head, 0B411H 
        jmp keluar_upda
        
    kekanan:   
        INC TARGET_GESER_KOLOM                         
        
           
        mov gambar_head, 0B410H 
        periksa KOLOM_NOW,MAX_COL,MIN_COL,TARGET_GESER_KOLOM ;gunakan macro periksa untuk memastikan ular tetap di area window
        jmp keluar_upda
            
    keatas:   
        DEC TARGET_GESER_BARIS
        
        mov gambar_head, 0B41EH 
        periksa BARIS_NOW,MIN_ROW,MAX_ROW,TARGET_GESER_BARIS ;gunakan macro periksa untuk memastikan ular tetap di area window
        jmp keluar_upda    
        
    yunojmp:
    jmp okdone

    kebawah:   
        INC TARGET_GESER_BARIS
        
        mov gambar_head, 0B41fH 
        periksa BARIS_NOW,MAX_ROW,MIN_ROW,TARGET_GESER_BARIS ;gunakan macro periksa untuk memastikan ular tetap di area window
        jmp keluar_upda 
        
    
    
    keluar_upda: 
    mov dl, target_geser_kolom       
    mov dh, target_geser_baris
    mov KOLOM_NOW, DL               ;UPDATE POSISI TARGET MENJADI POSISI SEKARANG
    MOV BARIS_NOW, DH
    mov current_head, dx  

    okdone:

    popa
    ret
update_position endp

gambar_ular proc near
    pusha 

    mov di, 0000h   

    snakes:                     ;loop to print snake

    mov dx, 0000H
    mov ax, 0000h

    mov bx, di
    mov cx, current_head[di]

    mov al, offset_atas         ;hitung alamat yang mau dimasukkan gambar
    add al, ch
    mov dl, 160
    mul dl
    mov bx, ax
    mov ah, 00h

    mov al, cl                   ;hitung kolomnya
    mov dl, 2
    mul dl
    add bx, ax 
    cmp di, 0
    je kepala
    mov dx,GAMBAR_EKOR
    jmp lompat
    kepala:
    mov dx, gambar_head
    mov CURRENT_KURSOR_KEPALA, bx
    lompat:
    mov es:[bx], dx

    add di, 2
    mov al, bod_size
    mov ah, 0
    mov cx, 2
    mul cx
    cmp di, ax
    jb snakes                   ;end of printing snake

    mov cx, food                ;ambil target kolom dan baris dari food
    mov al, offset_atas         ;ambil offset_atas dari perhitungan
    add al, ch                  ;tambahkan offset_atas dengan posisi baris dari food
    mov dl, 160                 ;kalikan dengan 0AH
    mul dl                      
    mov bx, ax                  ;pindahkan hasilnya ke bx
    mov ah, 00h                 ;isi highbyte dengan nol

    mov al, cl                  ;ambil nilai kolom
    mov dl, 2                   ;kalikan dengan 2, karena satu kolom di dua kotak memori
    mul dl
    add bx, ax                  ;pindahkan hasilnya ke bx
    mov dx, food_pic            ;ambil bentuk karakter dan warna nya dari variable food pic
    mov es:[bx], dx             ;end of printing food

    mov cx, bomb               ;print bomb
    mov al, offset_atas         ;hitung alamat yang mau dimasukkan gambar
    add al, ch
    mov dl, 160
    mul dl
    mov bx, ax
    mov ah, 00h

    mov al, cl                  ;print gambar di  layar
    mov dl, 2
    mul dl
    add bx, ax 
    mov dx, bomb_pic
    mov es:[bx], dx             ;end of printing bomb

    
    ;start rutin to cek is head colliding bomb or it's tails
    push ax
    push bx
    mov bx, CURRENT_KURSOR_KEPALA
    mov ax, ES:[bx]
    cmp ax, 0A4FEH
    pop BX
    pop ax
    jne tidakmati
    mov MATI, 1
    ;end of routine
    tidakmati:
    popa
    ret
gambar_ular endp

game proc near            ;prosedur untuk memainkan game snake
    pusha                 ;save all register
    mov ax, 0h
    mov current_head, ax
    gen_rand food
    ;mov BX,offset KANAN           
    CALL CLRSCR
    mov ax, 0b800h
    mov es, ax              ;set es to 0B800H (For Video memory)
    call tampilkan_score
ulangi:
    call special_clrscreen
    CALL GAMBAR_ULAR
    cmp MATI, 1
    je sudah_meninggal
    CALL DELAY1  
    cmp user_input, 1
    je skip     
    CALL MASUKAN
    skip:
    mov user_input, 0
    CALL UPDATE_POSITION 
    cmp berhenti, 0
    je ulangi
    jmp setopp
    sudah_meninggal:
    mov waktu_var, 5

    call sol
    call sol           
    call delay_not
    call delay_not

    call fa 
    call mi
    call delay_not
    call delay_not

    call re
    call do           
    call delay_not
    call delay_not
    mov waktu_var, 2
    call CLRSCR
    mov ah, 09H
    lea dx, tulisan_mati    ;print you dead
    int 21h
    mov ah,01H          ;press any key to continue
    int 21h
    setopp:mov ah, 01H ;clear buffer
    int 16h
    popa                  ;return all register
    ret
game endp

.startup
tampilmenu :
mov ax, 0003H
int 10H
mov dx,0
lea dx, menu
mov ah, 09H
int 21h
mov ah, 01H
int 21h
call clrscr
cmp al,'1'
mov waktu_var, 4
je mulai
jne keluar_help

mulai:
call do
call re           
call delay_not
call delay_not
                                             
                                             
call do 
call mi
call delay_not
call delay_not


call do
call fa
call delay_not
call delay_not

call do
call sol           
call delay_not  
call delay_not
jmp lompatin_aja

tampilmenu_helper:
jmp tampilmenu

lompatin_aja:
call do
call fa
call delay_not
call delay_not

call do 
call mi
call delay_not
call delay_not

call do
call re           
call delay_not
call delay_not


jmp pelindung


keluar_help:
    jmp keluar_menu

pelindung:


call do
call do           
call delay_not       
call delay_not
mov ax, 0003H
int 10H
mov dx,0
lagidongboy:
mov ah,01H
int 16h
jz skipaja
mov ah,00H
int 16h
jmp lagidongboy
skipaja:
lea dx, instruksi
mov ah, 09H
int 21h
mov ah, 01H

mov waktu_var, 2
int 21h
cmp al,'Q'
je tampilmenu_helper

call game
call init
jmp tampilmenu

keluar_menu:
mov ax, 0003H
int 10H
mov dx,0
lea dx, psnexit
mov ah, 09H
int 21h


.EXIT
end

