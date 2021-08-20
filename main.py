#!/usr/bin/python3

from ctypes import *

HS_FILE = 'minimax'
HS_LIB_FILE = f'./libffi_{HS_FILE}.so'
lib = cdll.LoadLibrary(HS_LIB_FILE)

BOARD = c_int * 10 # 3x3board + player
P1, P2 = 'X', 'O'

##########################
# Haskell interface
##########################
def pyToHs(arr, player):
    arr[9] = c_int(player)
    return BOARD(*arr)

def hsToPy(coords):
    y = coords % 10
    x = coords // 10
    return x, y

def minimax_ai(board, player):
    mv_x, mv_y = hsToPy (lib.minimax_ai_hs (pyToHs (board, player) ) )
    return mv_x, mv_y

##########################
# Python game utilities
##########################
def new_board():
    return BOARD( *[c_int(0) for i in range(10)] )

def num_to_char(num):
    if num == 0:
        return ' '
    elif num == 1:
        return P1
    else:
        return P2

def render(board):
    print('  0 1 2 ')
    print('  ------')
    for y in range(3):
        print(f"{y}|", end='')
        for x in range(3):
            c = num_to_char(board[x + 3*y])
            print(c, end=' ')
        print('|')
    print('  ------')

def get_move():
    while True:
        try:
            inpt = input("Enter the coordinates for your move (x,y): ").strip()
            coords = map(lambda s: s.strip(), inpt.split(','))
            coords = tuple(map(int, coords))
            if len(coords) != 2:
                raise Exception("Your input has to be two integers separated by a comma")
            return coords
        except:
            print(f"Your input needs to be two integers separated by a comma, not '{inpt}'.")

def is_valid_move(board, coords):
    x, y = coords 
    if y < 0 or y > 2 or x < 0 or x > 2:
        return False
    # elif x < 0 or x > 2:
    #     return False
    elif board[x + 3*y] != 0:
        return False
    return True

def make_move(board, mv, player):
    x,y = mv
    board[x + y*3] = player
    return board

def get_winner(board):
    brd = map(lambda x: x.value, board[:9])
    for i in range(3):
        if board[0 + 3*i]==board[1 + 3*i]==board[2 + 3*i] and board[0 + 3*i] != 0:
            return board[0 + 3*i]
        if board[i + 3*0]==board[i + 3*1]==board[i + 3*2] and board[i + 3*0] != 0:
            return board[i + 3*0]
    if (board[0 + 3*0]==board[1 + 3*1]==board[2 + 3*2] or board[2 + 3*0]==board[1 + 3*1]==board[0 + 3*2]) and board[1 + 3*1] != 0:
        return board[1 + 3*1]
    return 0

def check_draw(board):
    return not 0 in board[:9]

##########################
# Game loop and main
##########################
def game_loop():
    board = new_board()
    render(board)
    player = 1

    while True:
        if player == 1:
            mv = get_move()
        else:
            mv = minimax_ai(board, player)

        while not is_valid_move(board, mv):
            print(f"{mv} is an invalid move, the square is probably occupied by another piece.")
            mv = get_move()

        make_move(board, mv, player)
        render(board)

        winner = get_winner(board)
        if winner != 0:
            print(f"{num_to_char(winner)} won!")
            break

        if check_draw(board):
            print("Draw!")
            break

        player = 2 if player == 1 else 1

def main():
    lib.init_hs()
    try:
        game_loop()
    except:
        pass
    finally:
        lib.exit_hs()

if __name__ == '__main__':
    main()