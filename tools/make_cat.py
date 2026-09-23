from PIL import Image, ImageDraw
import math, sys, os
H=28; FW=40
OUT=(120,110,140,255); GOLD=(255,214,90,255); GOLD2=(240,170,60,255); EYE=(60,50,70,255)

SKINS = {
 "meowicorn": dict(body=(250,250,255), shade=(214,220,236), ear=(200,200,215), wings=[(255,196,224),(255,150,205),(238,105,180),(210,70,160)], blush=(255,170,190), out=OUT),
 "cherry":    dict(body=(240,92,104),  shade=(200,60,78),   ear=(255,150,150), wings=[(255,236,150),(255,214,90),(245,180,60),(220,140,40)], blush=(255,200,200), out=(110,40,55,255)),
 "mango":     dict(body=(255,170,70),  shade=(225,130,45),  ear=(255,200,120), wings=[(180,255,235),(120,230,210),(70,200,190),(40,160,160)], blush=(255,220,190), out=(130,70,20,255)),
 "lemon":     dict(body=(255,236,110), shade=(230,200,70),  ear=(255,245,170), wings=[(235,210,255),(200,170,255),(170,130,240),(140,100,220)], blush=(255,200,170), out=(140,110,30,255)),
 "minty":     dict(body=(140,225,160), shade=(100,190,125), ear=(190,245,200), wings=[(255,205,230),(255,160,210),(240,115,185),(215,80,165)], blush=(255,190,200), out=(40,110,70,255)),
 "blueberry": dict(body=(120,170,240), shade=(85,130,210),  ear=(170,205,255), wings=[(200,255,235),(150,240,210),(100,220,190),(60,190,170)], blush=(255,190,220), out=(40,60,130,255)),
 "plum":      dict(body=(170,120,220), shade=(135,85,190),  ear=(205,170,245), wings=[(255,230,150),(255,200,90),(250,160,60),(230,120,40)], blush=(255,190,230), out=(70,40,120,255)),
 "midnight":  dict(body=(62,58,80),    shade=(42,38,58),    ear=(95,90,115),   wings=[(255,120,120),(255,225,120),(130,230,150),(130,180,255)], blush=(200,120,150), out=(150,140,175,255)),
}

def make(skin, path):
    S=SKINS[skin]
    WHITE=S["body"]+(255,); SHADE=S["shade"]+(255,); GREY=S["ear"]+(255,); BLUSH=S["blush"]+(255,); OUTC=S["out"]
    W1,W2,W3,W4=[c+(255,) for c in S["wings"]]
    def px(d,x,y,c): d.point((x,y),c)
    def tail(d, pts):
        d.line(pts, fill=OUTC, width=4, joint="curve"); d.line(pts, fill=WHITE, width=2, joint="curve")
        x,y=pts[-1]; d.ellipse([x-1,y-1,x+1,y+1], fill=WHITE, outline=OUTC)
    def wing(d, ox, oy):
        rows=[(0,6),(1,8),(2,9),(3,9),(4,8),(5,6),(6,4)]; cols=[W1,W1,W2,W2,W3,W3,W4,W4]
        for i,(r,ln) in enumerate(rows):
            for k in range(ln): px(d, ox-k, oy+r, cols[min(len(cols)-1, k*len(cols)//max(1,ln))])
            px(d, ox-ln, oy+r, OUTC)
    def fan(d, ax, ay, a0, a1, lens):
        cols=[W1,W2,W2,W3,W3,W4,W4]; n=len(lens)
        for f in range(n):
            ang=math.radians(a0+(a1-a0)*f/(n-1))
            for k in range(lens[f]): px(d, ax+int(round(math.cos(ang)*k)), ay+int(round(math.sin(ang)*k)), cols[f])
            px(d, ax+int(round(math.cos(ang)*lens[f])), ay+int(round(math.sin(ang)*lens[f])), OUTC)
        for k in range(3): px(d, ax-k, ay, W4); px(d, ax-k, ay+1, W3)
    def head(d, ox, oy, cx, cy, wide=False):
        d.ellipse([ox+cx, oy+cy, ox+cx+16, oy+cy+14], fill=WHITE, outline=OUTC)
        d.polygon([(ox+cx+2,oy+cy+3),(ox+cx+3,oy+cy-2),(ox+cx+6,oy+cy+2)], fill=GREY, outline=OUTC)
        d.polygon([(ox+cx+11,oy+cy+2),(ox+cx+14,oy+cy-2),(ox+cx+15,oy+cy+3)], fill=GREY, outline=OUTC)
        d.polygon([(ox+cx+7,oy+cy+1),(ox+cx+9,oy+cy-3),(ox+cx+10,oy+cy+1)], fill=GOLD, outline=GOLD2)
        px(d, ox+cx+8, oy+cy-1, (255,240,170,255))
        px(d, ox+cx+6, oy+cy+6, EYE); px(d, ox+cx+12, oy+cy+6, EYE)
        if wide: px(d, ox+cx+6, oy+cy+5, EYE); px(d, ox+cx+12, oy+cy+5, EYE)
        px(d, ox+cx+9, oy+cy+9, W3); px(d, ox+cx+8, oy+cy+10, OUTC); px(d, ox+cx+10, oy+cy+10, OUTC)
        px(d, ox+cx+4, oy+cy+9, BLUSH); px(d, ox+cx+14, oy+cy+9, BLUSH)
    def leg(d, ox, oy, x0, y0, x1, y1): d.rectangle([ox+x0, oy+y0, ox+x1, oy+y1], fill=WHITE, outline=OUTC)
    GALLOP=[([4,10,26,25],0,[(6,17),(2,13),(0,8),(2,4),(5,5)],[(8,22,11,26),(12,21,15,25),(17,22,20,26),(21,21,24,25)]),
            ([3,8,27,23],-1,[(5,16),(0,15),(-4,12),(-4,8),(-1,7)],[(5,19,8,24),(9,18,12,23),(22,18,25,23),(26,19,29,24)]),
            ([4,10,26,25],0,[(6,17),(1,14),(-1,9),(1,5),(4,6)],[(8,20,11,23),(12,21,15,24),(21,21,24,26),(25,22,28,26)]),
            ([4,10,26,25],0,[(6,17),(2,13),(0,8),(2,4),(5,5)],[(7,21,10,26),(11,22,14,26),(21,20,24,23),(25,19,28,22)])]
    def cat(d, ox, oy, pose):
        if pose < 4:
            body, dy, tl, legs = GALLOP[pose]; oy += dy
            tail(d, [(ox+x, oy+y) for x,y in tl])
            d.ellipse([ox+body[0], oy+body[1], ox+body[2], oy+body[3]], fill=WHITE, outline=OUTC)
            d.ellipse([ox+body[0]+3, oy+body[3]-6, ox+body[2]-3, oy+body[3]-1], fill=SHADE)
            wing(d, ox+12, oy+body[1]+1); head(d, ox, oy, 15, body[1]-6, wide=(pose==1))
            for l in legs: leg(d, ox, oy, *l)
            return
        if pose == 4:
            tail(d, [(ox+6,oy+18),(ox+1,oy+16),(ox-3,oy+12),(ox-3,oy+8),(ox+0,oy+7)])
            d.ellipse([ox+4, oy+9, ox+26, oy+25], fill=WHITE, outline=OUTC); d.ellipse([ox+7, oy+19, ox+23, oy+24], fill=SHADE)
            fan(d, ox+15, oy+11, -150, -65, [8,10,11,11,10,9,7]); head(d, ox, oy, 15, 3, wide=True)
            for (lx,ly) in [(9,23),(13,23),(19,23),(23,23)]: d.rectangle([ox+lx, oy+ly, ox+lx+2, oy+25], fill=WHITE, outline=OUTC)
            return
        if pose == 5:
            tail(d, [(ox+4,oy+20),(ox+0,oy+18),(ox-3,oy+14),(ox-2,oy+10),(ox+1,oy+10)])
            d.ellipse([ox+2, oy+13, ox+29, oy+27], fill=WHITE, outline=OUTC); d.ellipse([ox+4, oy+22, ox+27, oy+26], fill=SHADE)
            head(d, ox, oy, 15, 9)
            for k in range(8): px(d, ox+8+k, oy+12, W2 if k<4 else W3); px(d, ox+9+k, oy+13, W1 if k<4 else W2)
            return
        tail(d, [(ox+4,oy+18),(ox-1,oy+17),(ox-5,oy+14),(ox-5,oy+10),(ox-2,oy+9)])
        d.ellipse([ox+2, oy+12, ox+26, oy+25], fill=WHITE, outline=OUTC); d.ellipse([ox+5, oy+20, ox+23, oy+24], fill=SHADE)
        if pose == 6: fan(d, ox+15, oy+13, -150, -70, [9,11,12,12,11,10,8])
        else: fan(d, ox+15, oy+16, 205, 130, [8,10,11,11,10,9,7])
        head(d, ox, oy, 15, 4, wide=True)
        for (lx,ly) in [(9,23),(14,24),(20,24)]: d.rectangle([ox+lx, oy+ly, ox+lx+2, oy+ly+2], fill=WHITE, outline=OUTC)
    sheet=Image.new("RGBA",(FW*8,H),(0,0,0,0)); d=ImageDraw.Draw(sheet)
    for i in range(8): cat(d, i*FW+7, 0, i)
    sheet.save(path)

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "art/cats"
    os.makedirs(out, exist_ok=True)
    for name in SKINS:
        make(name, os.path.join(out, "cat_%s.png" % name))
        print("wrote", name)
