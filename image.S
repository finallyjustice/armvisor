.section .main,#alloc
.globl os_image
os_image:
.incbin "guest/guest.img"
.globl os_image_end
os_image_end:
