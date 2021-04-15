import math

print("section .rodata")
print("sintable:")
for d in range(360):
    r = math.radians(d)
    print("dd {}".format(math.sin(r)))
print("costable:")
for d in range(360):
    r = math.radians(d)
    print("dd {}".format(math.cos(r)))
