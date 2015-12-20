import cv2
import numpy as np
import sys
import math
import argparse
import os

parser = argparse.ArgumentParser(
    description = "Generates texture atlas from provided images"
)
parser.add_argument(
    'path', metavar='path', type=str, nargs='+',
    help='an integer for the accumulator'
)
parser.add_argument(
    "-s", "--sheet", dest = "sheet", type = str, default = "./sheet.png",
    help = "Path to output atlas image"
)
parser.add_argument(
    "-i", "--index", dest = "index", type = str, default = "./index.lua",
    help = "Path to indexing Lua file"
)

args = parser.parse_args()

ims = []

for path in args.path:
    ims.append(cv2.imread(path, -1))

imcount = len(ims)

sortlist = sorted(zip(ims, args.path), key = lambda (im, p) : im.shape[0])

ims, path = zip(*sortlist)

# Read as (to, from, size)
D = np.zeros((imcount + 1, imcount + 1, 2))
C = np.zeros((imcount + 1, imcount + 1))
T = np.zeros((imcount + 1, imcount + 1))
# initialization
C[:, :] = np.inf
C[0, 0] = 0
T[:, :] = np.nan
T[0, 0] = 0
def cost(w, h):
    if w > 2048 or h > 2048:
        return np.inf
    return np.abs(w - h) + w * h

def readdim(D, r, c):
    if r - 1 < 0:
        return 0, 0
    else:
        return D[r, c, 0], D[r, c, 1]

for r in xrange(0, imcount + 1):
    w = 0
    h = 0
    # Find lowest cost prev step
    pr = np.argmin(C[:, r])
    ph = D[pr, r, 0]
    pw = D[pr, r, 1]
    for c in xrange(r + 1, imcount + 1):
        # Calculate current cost
        im = ims[c - 1]
        w = w + im.shape[1]
        h = max(h, im.shape[0])
        # Find cost
        cw = max(w, pw)
        ch = ph + h
        C[r, c] = cost(cw, ch)
        D[r, c, 0] = ch
        D[r, c, 1] = cw
        T[r, c] = pr

tc = C.shape[1] - 1
tr = np.argmin(C[:, -1])
"""
print "cost"
print C[:, -1]
print "trace"
print T
print "final dim"
print D[tr, tc]
print "final cost"
print C[tr, tc]
"""
fim = np.zeros((D[tr, tc, 0], D[tr, tc, 1], 4), dtype = "uint8")
splits = [imcount]
while tc > 1:
    print(tr)
    splits.append(int(tr))
    ntr = T[tr, tc]
    tc = tr
    tr = ntr

splits.append(0)
splits.reverse()
print(splits)

h = 0
indexfile = []
indexfile.append("local index = {")
for i in xrange(len(splits) - 1):
    w = 0
    th = 0
    for j in xrange(splits[i], splits[i + 1]):
        im = ims[j]
        # Create index
        p = path[j]
        name = os.path.splitext(os.path.basename(p))[0]
        line = "  %s = {x = %d, y = %d, w = %d, h = %d}," \
                % (name, w, h, im.shape[1], im.shape[0])
        indexfile.append(line)
        # Write image
        fim[h:(h + im.shape[0]), w:(w + im.shape[1]), :] = im
        w = w + im.shape[1]
        th = max(im.shape[0], th)

    h = h + th
indexfile.append("}")
indexfile.append("return index")
indexfile = map(lambda s : s + "\n", indexfile)
f = open(args.index, "w")
f.write(''.join(indexfile))
f.close()
cv2.imwrite(args.sheet, fim)
