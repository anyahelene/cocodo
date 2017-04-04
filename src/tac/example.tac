main() {
	result = fac(5);
	return result;
}

fac(n) {
		c  = n <= 1;
		if c goto END;
		t0 = n - 1;
		t1 = fac(t0);
		n  = n * t1;
END:	return n;
}


