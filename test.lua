require('router')
verbose = 0

selfRouter = RouterClass(os.getComputerID())
selfRouter.modems = ModemClass.getAllModems(selfRouter)

t = {3}
t[2]="w"
t.bla = "lalala"
t.router = {RouterClass(1,{ModemClass("left")}),id=77,t="asdjkashdh"}

print(table.toString(t))