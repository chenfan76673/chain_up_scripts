import os

#每周产生收益a(质押360天，一共52周，a的行数为52)
#但是分期180天发放，所以a的行数应该增加26周，或者更大一点
a = list()
with open('ccn周收益.txt', encoding='utf-8') as f:
    line = f.readline()
    while line:
        a.append(float(line.strip()))
        line = f.readline()
print(a)
print(len(a))
#每周发放收益b(每周产生的收益会发放27周，第一周发放25%，剩下的26周平均发放)
b = [[0 for i in range(78)] for i in range(52)]
for m in range(len(a)):
    for n in range(78):
        if m == n:
            b[m][n] = float(a[m])*0.25
        if m < n <= m + 26:
            b[m][n] = float(a[m])*0.75/26


#第m周应该发放的收益
def week_reward(m):
    sum1 = 0
    for i in range(52):
        sum1 += b[i][m]
    #print ("第" ,m,"周发放：",sum1)
    return sum1

#第m周产生的总收益
def sum_a(m):
    sum2=0
    for i in range(m):
        sum2+=a[i]
    return sum2

c = list()
#累计m周发放的收益
def sum_c(m):
    for i in range(m):
        c.append(week_reward(i))
    return sum(c)

def main(m):
    print("第",m,"周收益",a[m-1])
    print("第",m,"周发放",week_reward(m-1))
    print("累计发放收益：",sum_c(m))
    print("未发放收益：",sum_a(m)-sum(c))

#输入周数，从1开始
if __name__ == '__main__':
    main(54)







