'$dynamic
DECLARE function getPwd(seed as uinteger) as ubyte ptr
DECLARE function getRND (precission as uinteger = 703) as single


function getPwd(seed as uinteger) as ubyte ptr
	dim order(24) as uinteger
	dim op as ubyte ptr
	op = @order(0)
	op[0] = 3: op[1] = 2: op[2] = 1: op[3] = 4
	op = @order(1)
	op[0] = 2: op[1] = 4: op[2] = 3: op[3] = 1
	op = @order(2)
	op[0] = 1: op[1] = 3: op[2] = 4: op[3] = 2
	op = @order(3)
	op[0] = 4: op[1] = 1: op[2] = 2: op[3] = 3
	op = @order(4)
	op[0] = 2: op[1] = 1: op[2] = 4: op[3] = 3
	op = @order(5)
	op[0] = 2: op[1] = 1: op[2] = 3: op[3] = 4
	op = @order(6)
	op[0] = 1: op[1] = 3: op[2] = 2: op[3] = 4
	op = @order(7)
	op[0] = 1: op[1] = 4: op[2] = 3: op[3] = 2
	op = @order(8)
	op[0] = 4: op[1] = 3: op[2] = 2: op[3] = 1
	op = @order(9)
	op[0] = 2: op[1] = 3: op[2] = 4: op[3] = 1
	op = @order(10)
	op[0] = 4: op[1] = 3: op[2] = 1: op[3] = 2
	op = @order(11)
	op[0] = 3: op[1] = 4: op[2] = 2: op[3] = 1
	op = @order(12)
	op[0] = 4: op[1] = 1: op[2] = 3: op[3] = 2
	op = @order(13)
	op[0] = 1: op[1] = 4: op[2] = 2: op[3] = 3
	op = @order(14)
	op[0] = 4: op[1] = 2: op[2] = 3: op[3] = 1
	op = @order(15)
	op[0] = 3: op[1] = 1: op[2] = 2: op[3] = 4
	op = @order(16)
	op[0] = 3: op[1] = 1: op[2] = 4: op[3] = 2
	op = @order(17)
	op[0] = 2: op[1] = 4: op[2] = 1: op[3] = 3
	op = @order(18)
	op[0] = 3: op[1] = 2: op[2] = 4: op[3] = 1
	op = @order(19)
	op[0] = 2: op[1] = 3: op[2] = 1: op[3] = 4
	op = @order(20)
	op[0] = 1: op[1] = 2: op[2] = 3: op[3] = 4
	op = @order(21)
	op[0] = 3: op[1] = 4: op[2] = 1: op[3] = 2
	op = @order(22)
	op[0] = 1: op[1] = 2: op[2] = 4: op[3] = 3
	op = @order(23)
	op[0] = 4: op[1] = 2: op[2] = 1: op[3] = 3
	dim pwd((seed+4)*4+1) as ubyte
	dim pwdp as ubyte ptr
	dim num as uinteger
	dim nump as ubyte ptr
	dim incr as uinteger
	pwdp = @pwd(0)
	ord = seed mod 24
	incr = (4294967295 \ (seed+5))
	for a = 0 to seed+4
		num = num + incr
		nump = @num
		op = @order(ord)
		pwdp[a*4] = nump[op[0]-1]
		pwdp[a*4+1] = nump[op[1]-1]
		pwdp[a*4+2] = nump[op[2]-1]
		pwdp[a*4+3] = nump[op[3]-1]
		ord = (ord + 1) mod 24
	next
	op = callocate((seed+4)*4+3)
	op[0] = ((seed+4)*4) \ 255
	op[1] = ((seed+4)*4) mod 255
	for a = 0 to (seed+4)*4
		op[2+a] = pwdp[a]
	next
	getPwd = op
end function

function getRND (precission as uinteger = 703) as single
	static lastnum as single
	dd = (((timer*1000) mod 255000)) mod 65536
	aa! = dd
	aa! = aa! mod precission
	aa! = aa! / precission+lastnum
	while aa! > 1
		aa!=aa!-1
	wend
	lastnum = aa!
	getRND = aa!
end function