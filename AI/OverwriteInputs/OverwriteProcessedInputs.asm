################################################################################
# Address: 0x8006b0dc
# Same point as Playback/Core/RestoreGameFrame.asm: immediately before
# Recording/SendGamePreFrame.asm (8006b0e0) and processed button edge logic.
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

# 4 x (u32 enabled + 44 bytes). D9 has already committed this frame.
backup 0x100
mr r30, r31
branchl r12, FN_ShouldRecord
cmpwi r3, 0
beq Exit
mr r3, r30
branchl r12, FN_GetIsFollower
cmpwi r3, 0
bne Exit

# EXI DMA invalidates whole 32-byte cache lines. Align the buffer and keep
# both the stack back-chain and saved registers outside those lines.
addi r29, r1, 39
rlwinm r29, r29, 0, 0, 26
li r3, 0xDA
stb r3, 0(r29)
mr r3, r29
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer
mr r3, r29
li r4, 192
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

# Use the controller port, not the player slot (different in some modes).
lbz r28, 0x618(r30)
cmpwi r28, 4
bge Exit
mulli r3, r28, 48
add r29, r29, r3
lwz r3, 0(r29)
cmpwi r3, 1
bne Exit
addi r29, r29, 4

# Match the pre-frame RNG boundary as well as inputs. CPU AI consumes RNG
# that human-controlled playback does not. No position/action resync.
load r4, 0x804D5F90
lwz r3, 40(r29)
stw r3, 0(r4)

lwz r3, 0(r29)
stw r3, 0x620(r30)
lwz r3, 4(r29)
stw r3, 0x624(r30)
lwz r3, 8(r29)
stw r3, 0x638(r30)
lwz r3, 12(r29)
stw r3, 0x63C(r30)
lwz r3, 16(r29)
stw r3, 0x650(r30)
lwz r3, 20(r29)
stw r3, 0x65C(r30)

# Physical fields read by the recorder. Buttons used by the fighter's
# edge logic are the processed word above, exactly as in Slippi playback.
load r4, 0x804C1FAC
mulli r3, r28, 0x44
add r4, r4, r3
lhz r3, 24(r29)
sth r3, 2(r4)
lwz r3, 28(r29)
stw r3, 0x30(r4)
lwz r3, 32(r29)
stw r3, 0x34(r4)

# Restore the raw stick history consumed by UCF (Playback logic).
load r4, 0x804C1F78
lbz r3, 1(r4)
subi r3, r3, 1
cmpwi r3, 0
bge RawIndexReady
addi r3, r3, 5
RawIndexReady:
mulli r3, r3, 0x30
load r4, 0x8046B108
add r4, r4, r3
mulli r3, r28, 0xC
add r4, r4, r3
lbz r3, 36(r29)
stb r3, 2(r4)
lbz r3, 37(r29)
stb r3, 3(r4)
lbz r3, 38(r29)
stb r3, 4(r4)
lbz r3, 39(r29)
stb r3, 5(r4)

Exit:
restore 0x100
lbz r0, 0x2219(r31)
