import sys, re

if sys.argv[1] == 'out':
	sourcename = 'font-source-new'
	constname = 'font-const'
	if len(sys.argv) > 2:
		sourcename = sys.argv[2]
	if len(sys.argv) > 3:
		constname = sys.argv[3]
	print 'exporting %s to %s' % (sourcename, constname,)
	letters = []
	for cn in range(128):
		letter = []
		for r in range(12):
			letter.append('')
		letters.append(letter)
	lc = 0
	cn = None
	r = 12
	for l in open(sourcename, 'rt'):
		m = re.match('^#([0-9]+)\s+-\s+\'.\'\s*$', l)
		if m:
			if r != 12:
				print 'incomplete char %d' % (lc - 1,)
				sys.exit(1)
			r = 0
			cn = int(m.groups(1)[0])
			if cn != lc:
				print 'char %d out of order' % (cn,)
				sys.exit(1)
			lc += 1
		else:
			m = re.match('^([.0]{8})\s*(?:#.*)?$', l)
			if m:
				if r >= 12:
					print 'too many lines in char %d' % (cn,)
					sys.exit(1)
				letters[cn][r] = m.groups(1)[0]
				r += 1
			elif l.strip() != '':
				print 'garbage line \'%s\'' % (l,)
				sys.exit(1)
	topvals = [0] * 128
	midvals = [0] * 128
	botvals = [0] * 128
	for cn in range(128):
		for r in range(12):
			if r % 4 == 0:
				v = 0
			for c in range(8):
				v |= (1 if letters[cn][r][c] != '.' else 0) << (c + (r % 4) * 8)
			if r / 4 == 0:
				topvals[cn] = v
			elif r / 4 == 1:
				midvals[cn] = v
			elif r / 4 == 2:
				botvals[cn] = v
	f = open(constname, 'wt')
	for j in range(16):
		f.write('long  $%08X,$%08X,$%08X,$%08X,$%08X,$%08X,$%08X,$%08X' % tuple(topvals[j * 8:j * 8 + 8]))
		if j == 0:
			f.write('  \'top')
		f.write('\n')
	f.write('\n')
	for j in range(16):
		f.write('long  $%08X,$%08X,$%08X,$%08X,$%08X,$%08X,$%08X,$%08X' % tuple(midvals[j * 8:j * 8 + 8]))
		if j == 0:
			f.write('  \'middle')
		f.write('\n')
	f.write('\n')
	for j in range(16):
		f.write('long  $%08X,$%08X,$%08X,$%08X,$%08X,$%08X,$%08X,$%08X' % tuple(botvals[j * 8:j * 8 + 8]))
		if j == 0:
			f.write('  \'bottom')
		f.write('\n')
elif sys.argv[1] == 'in':
	constname = 'font-const'
	sourcename = 'font-source'
	if len(sys.argv) > 2:
		constname = sys.argv[2]
	if len(sys.argv) > 3:
		sourcename = sys.argv[3]
	print 'importing %s into %s' % (constname, sourcename,)
	letters = []
	for cn in range(128):
		letter = []
		for r in range(12):
			row = []
			for c in range(8):
				row.append('.')
			letter.append(row)
		letters.append(letter)
	lc = 0
	for l in open(constname, 'rt').readlines():
		m = re.match('^long\\s+' + '\\$([0-9a-fA-F]{8}),\\s*'*7 + '\\$([0-9a-fA-F]{8})\\s*(?:\'.*)?$', l)
		if m:
			vals = map(lambda x: int(x, 16), m.groups())
			for v in vals:
				for r in range(4):
					for c in range(8):
						cn = lc % 128
						row = (lc / 128) * 4 + r
						letters[cn][row][c] = '0' if v & (1 << (r * 8 + c)) else '.'
				lc += 1
	if lc != 128 * 3:
		print 'wrong number of values:', lc
		sys.exit(1)
	f = open(sourcename, 'wt')
	for cn in range(128):
		f.write('#%d - \'%c\'\n' % (cn, chr(cn) if cn > 32 else ' '))
		for r in range(12):
			f.write(''.join(letters[cn][r]) + '\n')
		f.write('\n')
	f.close()
else:
	print 'not doing anything'
