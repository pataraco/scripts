# f = open('demo.txt', mode='r')
with open('demo.txt', mode='r') as f:
    # f.write("Hello world!\n")
    # file_content = f.read()
    file_content = f.readlines()
    # file_content = f.readline()


print(f"file content: '{file_content}'")
print(f"file content [0][-1]: '{file_content[0][-1]}'")
for l in file_content:
    print(l[:-1])
