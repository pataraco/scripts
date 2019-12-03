#!/usr/bin/python

# Fibonacci numbers module

# print out the Fibonacci series up to n
def nums(n):
    a, b = 0, 1
    while b <= n:
        print b,
        a, b = b, a+b
    print

# return a list of the Fibonacci series up to n
def list(n):
    list = []
    a, b = 0, 1
    while b <= n:
        list.append(b)
        a, b = b, a+b
    return list

if __name__ == "__main__":
    import sys
    #print sys.argv[0]
    nums(int(sys.argv[1]))

'''
# try this
#
 Python 2.7.6 (default, Jun 22 2015, 17:58:13)
 [GCC 4.8.2] on linux2
 Type "help", "copyright", "credits" or "license" for more information.
 >>> import fibonacci
 >>> fibonacci.list(100)
 [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
 >>> fibonacci.list(89)
 [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89]
 >>> fibonacci.__name__
 'fibonacci'
 >>> __name__
 '__main__'
 >>> fib = fibonacci.nums
 >>> fib(250)
 1 1 2 3 5 8 13 21 34 55 89 144 233
'''
