from PIL import Image

W, H = 32, 22

COLORS = {
    "O": (200, 116, 47, 255),
    "D": (139, 74, 30, 255),
    "K": (42, 26, 16, 255),
    "W": (255, 255, 255, 255),
    "R": (224, 48, 48, 255),
    "M": (120, 20, 30, 255),
    "H": (120, 14, 28, 255),
    "L": (190, 40, 56, 255),
}

BASE = [
    ".L.........L....................",
    ".HH.......HH....................",
    "..HH.....HH.....................",
    "..OHHO..OHHO....................",
    "..OOOOOOOOOOO...................",
    ".OOOOOOOOOOOOO..................",
    ".OOWWWOOOWWWOO..................",
    ".OOWWWOOOWWWOO..................",
    ".OOWWWOOOWWWOO..................",
    "KKOOOOOOOOOOOO..................",
    "KKKOOOOOOOOOOOO.................",
    "KKOOOOOOOOOOOOOOOOOOOOOOOOOO....",
    ".OOOOOOOOOOOOOOOOOOOOOOOOOOO....",
    "..OOOOOOOOOOOOOOOOOOOOOOOOOO....",
    "....OOOOOOOOOOOOOOOOOOOOOOOO....",
    ".....OOOOOOOOOOOOOOOOOOOOOOO....",
    ".....OOOOOOOOOOOOOOOOOOOOOO.....",
    ".....OOOOOOOOOOOOOOOOOOOOOO.....",
    ".....ODDDDDDDDDDDDDDDDDDDDO.....",
    "................................",
    "................................",
    "................................",
]

BROWS = [
    ".KKOOOOOKK.",
    "...KK.KK...",
]

ANGER = [
    "..R...R..",
    "..R...R..",
    "RRR...RRR",
    ".........",
    "RRR...RRR",
    "..R...R..",
    "..R...R..",
]
ANGER_AT = [(15, 0), (16, 1), (15, 0)]

PUPILS = [[(1, 2), (1, 2)], [(0, 1), (2, 1)], [(2, 2), (0, 2)]]

MOUTHS = [
    [".OKWKWKWKO", "..OOOOOOOO"],
    [".OWKWKWKOO", ".OMMMMMMOO", ".OWKWKWKOO"],
    [".OKWKWKWKO", "..OOOOOOOO"],
]

TAILS = [
    ["....K", "...OO", "..OO.", ".OO..", "OO...", "O...."],
    [".....", ".K...", ".OO..", "..OO.", "..OO.", ".OO.."],
    [".....", ".....", ".....", "K....", "OOO..", "..OOO"],
]

LEG_X = [4, 10, 18, 24]
LEG_LEAN = [[0, 0, 0, 0], [-1, 1, -1, 1], [1, -1, 1, -1]]

def blit(canvas, rows, ox, oy):
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                canvas[oy + y][ox + x] = ch

def frame(i):
    canvas = [list(row) for row in BASE]
    blit(canvas, TAILS[i], 27, 6)
    blit(canvas, BROWS, 2, 5)
    blit(canvas, ANGER, ANGER_AT[i][0], ANGER_AT[i][1])
    for (px, py), ex in zip(PUPILS[i], (3, 9)):
        canvas[6 + py][ex + px] = "K"
    blit(canvas, MOUTHS[i], 0, 12)
    for x, lean in zip(LEG_X, LEG_LEAN[i]):
        for row in range(4):
            shift = round(lean * row / 3)
            width = 4
            for dx in range(width):
                canvas[18 + row][x + shift + dx] = "O" if row < 3 else "D"
    return canvas

def main():
    sheet = Image.new("RGBA", (W * 3, H), (0, 0, 0, 0))
    for i in range(3):
        canvas = frame(i)
        for y in range(H):
            for x in range(W):
                ch = canvas[y][x]
                if ch in COLORS:
                    sheet.putpixel((i * W + x, y), COLORS[ch])
    sheet.save("art/dog.png")

if __name__ == "__main__":
    main()
