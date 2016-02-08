*----------------------------------------------------------------------
* Programmer: Kevin O'mara
* Class Account: masc0779
* Assignment or Title: MNK Game
* Filename: NoughtsAndCrosses.s
* Date completed: February 2nd, 2016
* Version: 2.0.0
*----------------------------------------------------------------------
* Problem statement: Make a generic m,n,k game (max 9x9x9)
*   currently supported - Tic-tac-toe & Connect Four
*
* Input: grid locations typed by both players
* Output: current state of game grid
* Error conditions tested:
*   *TO BE FIXED
*   - player enters anything besides #1-9, including entering nothing
*   - player overwrite squares (maybe make optional? ~ espionage!)
*
* Included files: /home/ma/cs237/bsvc/iomacs.s
* Method and/or pseudocode: 
*
*   Initialize:
*       user input for gametype
*       user input for grid dimensions and win condition
*       reset necessary variables for replaying game
*       print graphics
*
*   Game Loop:
*   do {
*       toggle player
*       check game type
*       user input
*       modify grid (i.e. place piece) -> unique to gametype
*       update graphics
*       check win condition
*       }
*   while (win condition or draw not met)
*
*   Game End:
*       print game end message
*       query replay
*       goodbye
*
*   The grid locations are entered row column, i.e 12:
*    1 2 3 ...
*  1| | | |
*  2| | | |
*  3| | | |
* ...
*
* References: 
*   1) CS237 Machine Organization & Assembly Language Programming
*   2) Excerpts from Programmer's Reference Manual
*
* Future Plans?:
*   larger graphics + animation
*   \ /     /-\
*    X      | |
*   / \     \-/
*----------------------------------------------------------------------
* rm \,outfile*
        ORG     $0
        DC.L    $3000           * Stack pointer value after a reset
        DC.L    start           * Program counter value after a reset
        ORG     $3000           * Start at location 3000 Hex
*
*----------------------------------------------------------------------
*
#minclude /home/ma/cs237/bsvc/iomacs.s
*
*----------------------------------------------------------------------
*
* Register use
*   D0  manipulated by I/O macros
*   D1  target row (user input)
*   D2  target column (user input)
*   D3  current player (+1 or -1)       * +1=X's, -1=O's
*   D4  win condition counter
*   D5  temporary variable (for shifting A1 and arithmetic)
*   D6  row loop counter
*   D7  column loop counter
*
*   A1  grid pointer
*   A2  graphics pointer
*
*----------------------------------------------------------------------
*
start:  initIO                  * Initialize (required for I/O)

*** SelectGametype ------------------------------------------------------------*
* user selects gametype
        lineout welcome
        lineout typequery
        lineout typelist
        linein  input
        cvta2   input,#1
        cmp.b   #1,D0
        beq     pictictactoe
        cmp.b   #2,D0
        move.b  #2,gametype
        bra     endpictype
pictictactoe:
        move.b  #1,gametype
endpictype:
        
*** ---------------------------------------------------------------------------*

*** InitializeSizeAndWinCondition ---------------------------------------------*
* initialize grid dimensions and win condition
        lineout sizeprompt
        linein  input
        cvta2   input,#1        * set number of rows
        tst.b   D0              * if 0, default setup
        beq     defaultsetup
        move.b  D0,numrows
        cvta2   input+1,#1      * set number of columns
        move.b  D0,numcols
        lineout winprompt       * set number 'in a row' for win condition
        linein  input
        cvta2   input,#1
        move.b  D0,numwin
        bra     enddefault
        
defaultsetup:
        move.b  gametype,D5     * select gametype for default
        cmp.b   #1,D5
        beq     defaulttictactoe
        move.b  #6,numrows
        move.b  #7,numcols
        move.b  #4,numwin
        bra     enddefault
defaulttictactoe:
        move.b  #3,numrows
        move.b  #3,numcols
        move.b  #3,numwin
enddefault:
        
*** ---------------------------------------------------------------------------*

*** ResetVariables ------------------------------------------------------------*
* resets variables which are otherwise modified between games
replay: move.l  #-1,D3          * set starting player
        move.b  #$4F,playersymbol   * set starting player symbol 'O'
        clr.w   D5              * set number of turns until a draw (Cat's Game)
        clr.w   D6
        move.b  numrows,D6
        move.b  numcols,D7
        mulu.w  D7,D6
        move.b  D6,turnlimit
        lea     grid,A1         * set grid to all zeroes
        move.b  #89,D5          * for (D5=89; D5>0; D5--)
gridset:
        move.b  #0,(A1)+
        subq.b  #1,D5
        tst.b   D5
        bgt     gridset
*** ---------------------------------------------------------------------------*
        
*** PopulateInitialGraphics ---------------------------------------------------*
* fills graphics with beginning empty board state
        lea     graphics,A2
* for (D6=0; D6<numrows; D6++) {
        clr.b   D6
forrow: cmp.b   numrows,D6
        bge     endrow
*   for (D7=0; D7<numcols; D7++) {
        clr.b   D7
forcol: cmp.b   numcols,D7
        bge     endcol
        move.b  #$7C,(A2)+      * insert '|'
        move.b  #$20,(A2)+      * insert ' '
        addq.b  #1,D7
        bra     forcol
endcol:
*   }
        move.b  #$7C,(A2)+      * insert '|'
        move.b  #$0D,(A2)+      * insert CR (carriage return)
        move.b  #$0A,(A2)+      * inster LF (line feed)
        addq.b  #1,D6
        bra     forrow
endrow:
* }
        move.b  #$00,-(A2)      * instert null terminator at end of grahpics
*** ---------------------------------------------------------------------------*

        lineout graphics        * print starting grid

*** MainGameLoop --------------------------------------------------------------*
gameloop:
        neg.b   D3              * toggle player (+1 <-> -1)
        tst.b   D3              * toggle player symbol ('X' <-> 'O')
        bpl     playerX
        move.b  #$4F,playersymbol
        bra     togglesymbol
playerX:
        move.b  #$58,playersymbol
togglesymbol:

*** CheckGameType -------------------------------------------------------------*
        lineout nextmoveprompt
        move.b  gametype,D5     * select prompt (1 or 2 numbers)
        cmp.b   #1,D5
        beq     onekeyjump
        lineout onekeyprompt
        bra     takeinput
onekeyjump:        
        lineout twokeyprompt

takeinput:
        linein  input
        cvta2   input,#1        * extract row -> D1
        move.l  D0,D1
        subq.b  #1,D1
        cvta2   input+1,#1      * extract column -> D2
        move.l  D0,D2
        subq.b  #1,D2

        cmp.b   #1,D5           * select gametype for ModifyGrid mechanics
        beq     typetictactoe
*** ---------------------------------------------------------------------------*
        
*** ModifyGrid -> Connect Four ------------------------------------------------*
        * move grid pointer (A1) to bottom of chosen column, move up until an
        * open spot is available

        move.l  D1,D2           * load row,col to registers D1,D2
        move.b  numrows,D1
        subq.b  #1,D1
        move.b  D1,D6           * load row & col loop counters into D6,D7
        move.b  D2,D7
        lea     grid,A1         * grid(D1,D2) -> A1 (i.e. acces matrix location)
        clr.w   D5
        move.b  numcols,D5
        mulu.w  D1,D5
        add.w   D2,D5
        adda.w  D5,A1           * A1 += row*numcols+col
        
dropchecker:
        tst.b   (A1)
        beq     openspot
        subq.b  #1,D6           * decrement row counter & grid pointer
        clr.w   D5
        move.b  numcols,D5
        sub.w   D5,A1
        cmp.b   numrows,D6      * check for out of bounds (i.e. hit top wall)
        bge     noneopen        * ^^ doesn't quite seem to work...
        bra     dropchecker
        
noneopen:
        clr.b   D1              * to avoid out of bounds in Check WinCondition
        clr.b   D2
        bra     final
        
openspot:
        move.b  D3,(A1)         * place +1 or -1
final:
        move.b  D6,D1           * mark final point for use in CheckWinCondition
        move.b  D7,D2
        bra     updategraphics
*** ---------------------------------------------------------------------------*

*** ModifyGrid -> Tic-Tac-Toe -------------------------------------------------*
        * move grid pointer (A1) to chosen grid location and place +1 or -1\
typetictactoe:
        lea     grid,A1         * grid(D1,D2) -> A1 (i.e. acces matrix location)
        clr.w   D5
        move.b  numcols,D5
        mulu.w  D1,D5
        add.w   D2,D5
        adda.w  D5,A1           * A1 += row*numcols+col
        move.b  D3,(A1)         * place +1 or -1
*** ---------------------------------------------------------------------------*

*** UpdateGraphics ------------------------------------------------------------*
        * move graphics pointer (A2) to chosen location and place 'X' or 'O'
        * note, each line is stored as: '| | ...| | |LFCR'
updategraphics:
        lea     graphics,A2
        clr.w   D5              * (numcols*2+3)
        move.b  numcols,D5
        lsl.b   #1,D5
        addq.b  #3,D5
        mulu.w  D1,D5           * row*()
        add.b   D2,D5           * (2*col+1)
        add.b   D2,D5
        addq.b  #1,D5
        adda.w  D5,A2           * A2 += row*(numcols*2+3)+(2*col+1)
        move.b  playersymbol,(A2)   * place 'X' or 'O'
*** ---------------------------------------------------------------------------*

        lineout graphics

*** CheckWinCondition ---------------------------------------------------------*
* checks horizontal, vertical, and two diagonal lines centered on the player's
* move to see if the game is over.
*
* general pseudocode:
*
*   find starting grid point from straight/diagonal line, use this to set
*       D6 -> row counter
*       D7 -> col counter
*       A1 -> grid pointer
*
*   check A1 to see if grid point matches player D3 ('+1' or '-1'), then
*   increment or reset win counter (D4) accordingly
*
*   update row/col counter & grid pointer
*   check win condition
*   check loop condition (has D6 or D7 hit a wall?)

*HORIZONTAL ----------
        move.b  D1,D6
        moveq   #0,D7
        clr.b   D4              * D4 == win counter
        
        lea     grid,A1         * grid(D1,D2) -> A1
        clr.w   D5
        move.b  numcols,D5
        mulu.w  D6,D5
        add.w   D7,D5
        adda.w  D5,A1           * A1 += row*numcols+col
horizontalcheck:
        cmp.b   (A1),D3         * if (A1 == player) D4++, else D4=0
        beq     zero_1
        clr.b   D4
        bra     done_1
zero_1: addq.b  #1,D4
done_1:
        cmp.b   numwin,D4       * if (win counter >= numwin)
        bge     endwincondition
        addq.b  #1,D7           * increment col counter & grid pointer
        addq.w  #1,A1
        cmp.b   numcols,D7      * if (col counter >= numcols)
        blt     horizontalcheck

*VERTICAL ----------
        moveq   #0,D6
        move.b  D2,D7
        clr.b   D4              * D4 == win counter

        lea     grid,A1         * grid(D1,D2) -> A1
        clr.w   D5
        move.b  numcols,D5
        mulu.w  D6,D5
        add.w   D7,D5
        adda.w  D5,A1           * A1 += row*numcols+col
verticalcheck:
        cmp.b   (A1),D3         * if (A1 == player) D4++, else D4=0
        beq     zero_2
        clr.b   D4
        bra     done_2
zero_2: addq.b  #1,D4
done_2:
        cmp.b   numwin,D4       * if (win counter >= numwin)
        bge     endwincondition
        addq.b  #1,D6           * increment row counter & grid pointer
        clr.w   D5
        move.b  numcols,D5
        add.w   D5,A1
        cmp.b   numrows,D6      * if (row counter >= numrows)
        blt     verticalcheck

*DIAGONAL (TOP-LEFT) ----------
        * set row & col to top left -> diagonal line until hitting closest wall
        cmp     D1,D2
        bgt     closer1         * row is closer to wall than col
        move.b  D2,D5
        bra     end1closer
closer1:
        move.b  D1,D5
end1closer:
        move.b  D1,D6
        move.b  D2,D7
        sub.b   D5,D6
        sub.b   D5,D7
        clr.b   D4              * D4 == win counter

        lea     grid,A1         * grid(D1,D2) -> A1
        clr.w   D5
        move.b  numcols,D5
        mulu.w  D6,D5
        add.w   D7,D5
        adda.w  D5,A1           * A1 += row*numcols+col
topleftdiagonal:
        cmp.b   (A1),D3         * if (A1 == player) D4++, else D4=0
        beq     zero_3
        clr.b   D4
        bra     done_3
zero_3: addq.b  #1,D4
done_3:
        cmp.b   numwin,D4       * if (win counter >= numwin)
        bge     endwincondition
        addq.b  #1,D6           * increment row & counter & grid pointer
        addq.b  #1,D7
        clr.w   D5
        move.b  numcols,D5
        add.w   D5,A1
        addq.w  #1,A1
        cmp.b   numrows,D6      * if (row counter >= numrows)
        bge     endtopleftdiagonal
        cmp.b   numcols,D7      * if (col counter >= numcols)
        bge     endtopleftdiagonal
        bra     topleftdiagonal
endtopleftdiagonal:

*DIAGONAL (TOP-RIGHT) ----------
        * set row & col to top left -> diagonal line until hitting closest wall
        move.b  numcols,D5
        sub.b   D2,D5
        subq.b  #1,D5
        cmp     D1,D5
        bgt     closer2         * row is closer to wall than col
        bra     end2closer
closer2:
        move.b  D1,D5
end2closer:
        move.b  D1,D6
        move.b  D2,D7
        sub.b   D5,D6
        add.b   D5,D7
        clr.b   D4              * D4 == win counter

        lea     grid,A1         * grid(D1,D2) -> A1
        clr.w   D5
        move.b  numcols,D5
        mulu.w  D6,D5
        add.w   D7,D5
        adda.w  D5,A1           * A1 += row*numcols+col
toprightdiagonal:
        cmp.b   (A1),D3         * if (A1 == player) D4++, else D4=0
        beq     zero_4
        clr.b   D4
        bra     done_4
zero_4: addq.b  #1,D4
done_4:
        cmp.b   numwin,D4       * if (win counter >= numwin)
        bge     endwincondition
        addq.b  #1,D6           * increment row & counter & grid pointer
        subq.b  #1,D7
        clr.w   D5
        move.b  numcols,D5
        add.w   D5,A1
        subq.w  #1,A1
        cmp.b   numrows,D6      * if (row counter >= numrows)
        bge     endtoprightdiagonal
        tst.b   D7              * if (col counter <= numcols)
        blt     endtoprightdiagonal
        bra     toprightdiagonal
endtoprightdiagonal:

* ----------

        subq.b  #1,turnlimit    * check for draw
        tst.b   turnlimit
        ble     drawmessage
        bra     gameloop        * jump to start of game loop for next turn
*** ---------------------------------------------------------------------------*
*** ---------------------------------------------------------------------------*

*** GameEnd -------------------------------------------------------------------*
endwincondition:
        clr.l   D0              * update win message: # in a row & 'X' or 'O'
        move.b  numwin,D0
        cvt2a   winner,#1
        lea     winner,A2
        adda.w  #19,A2
        move.b  playersymbol,(A2)
        lineout winner
        bra     queryreplay
        
drawmessage:
        lineout catsgame
        
queryreplay:
        lineout skipline
        lineout promptreplay    * note: replay saves dimensions & win condition
        linein  input
        move.b  input,D5
        cmp.b   #'Y',D5
        beq     replay
        cmp.b   #'y',D5
        beq     replay
        lineout bye
        
        break                   * Terminate execution
        
*** ---------------------------------------------------------------------------*
        
*
*----------------------------------------------------------------------
*       Storage declarations
*   note: $0D == CR (carriage return) -> return cursor to beginning of line
*         $0A == LF (linefeed) -> move cursor to next line
*      $0D$0A == CRLF == newline ('\n')

gametype:   ds.b    1
numrows:    ds.b    1
numcols:    ds.b    1
numwin:     ds.b    1
turnlimit:  ds.b    1
grid:       dcb.b   81,0        * max 9x9 grid, 2's compliment +1=X, -1=O, 0=' '
graphics:   dcb.b   189,0       * each cell == '| ', with a |,CR,LF at end
input:      ds.b    82

* game turn prompts
nextmoveprompt: dc.b    'Your turn Player '
playersymbol:   dc.b    'O,',0
onekeyprompt:   dc.b    'select a column to drop your checker.',0
twokeyprompt:   dc.b    'select a square as row column, i.e. 12',0

* introduction prompts
welcome:    dc.b    'Welcome to Noughts and Crosses!.',0
typequery:  dc.b    'What would you like to play?',0
typelist:   dc.b    '1) Tic-Tac-Toe',$0D,$0A,'2) Connect Four',0
sizeprompt: dc.b    'Enter size of the grid as row column, i.e. 33 (max 9x9).'
sizenext:   dc.b    $0D,$0A,'-> (0 for default game setup)',0
winprompt:  dc.b    'How many in a row to win (1-9)?',0

* game end messages
winner:     dc.b    '3 in a row, Player O wins!',0
skipline:   dc.b    0
promptreplay:   dc.b    'Would you care to play again (y/n)?',0
bye:        dc.b    'Goodbye.',0
catsgame:   dc.b    'It',$27,'s a draw!  Cat',$27,'s Game.',0

            end