: # Start Perl. sh will execute the next 2 lines but Perl won't.
eval 'exec perl -S $0 ${1+"$@"}'
if 0;

require 5;

$hdl = "verilog_parser";
$vpp = "verilog_preprocessor";
$espmess = "behavioral module";
$espmess2 = "complicated ports";

die "usage: verilog_to_sue file...\n" unless @ARGV;

# generates module_name.sue for each module in the files

# contents of sue file:
# icon
# schematic of instantiations, or notice if module more than just structural

# pass 1 - read the verilog files
# pass 2 - write the sue files
# pass 3 - write the hierarchy

$vsbi = 30; # vertical space between instances and assigns
$ybci = 20; # bus combine increment

$inoutmap{"output"} = "output";
$inoutmap{"input"} = "input";
$inoutmap{"inout"} = "input";

pass1();
pass2();
pass3();
exit 0;

sub pass1 {
	foreach $file (@ARGV) {
		die "can't read file $file\n" unless -r $file;
	}
	open(IN, "$vpp @ARGV | $hdl|") || die "trouble running parser\n";
	set("IN");
	while (($cmd, $nargs, $value, $detail) = (get(0))) {
		if ($cmd eq "module") { module(); next; }
	}
	close(IN);
}

sub module {
	undef %parameter;
	$module = getid(1);   # $module global for all sorts of stuff
	push(@modules, $module);
	print "reading module $module\n";
	while(($cmd, $nargs, $value, $detail) = (get(1))) {
		return if $esp{$module};
		if ($cmd eq "parameter")
			{ parameter(2); next; }
		if ($cmd eq "portorder")
			{ portorder(2); next; }
		if ($cmd =~ /^(input|output|inout)$/)
			{ port($cmd, 2); next; }
		if ($cmd eq "instances")
			{ instances(2); next; }
		if ($cmd =~
			/^(assign|wire|triand|trior|tri1|tri|supply[01]|wor|trireg)$/)
				{ netORassign(2); next; }
		if ($cmd eq "real")
			{ next; }  # ignore
		if ($cmd eq "time")
			{ next; }  # ignore
		if ($cmd eq "register")
			{ next; }  # ignore
		$esp{$module} = "$cmd at top level";
	}
}

sub portorder {
	local($level) = @_;
	while(($cmd, $nargs, $value, $detail) = get($level)) {
		if ($cmd eq "id") {
			$portorder{$module} .= " $value";
		} elsif ($cmd eq "bit") {
			local($id, $bit) = getbit($level+1);
			$portorder{$module} .= " $id";
		} elsif ($cmd eq "range") {
			local($id, $from, $to) = getrange3($level+1);
			$portorder{$module} .= " $id";
		}
	}
}

sub parameter {
	local($level) = @_;
	while(($cmd, $nargs, $value, $detail) = get($level)) {
		return if $esp{$module};
		if ($cmd eq "assign") {
			local($id) = getid($level+1);
			local($n) = getnum($level+1);
			if ($esp{$module}) {
				# skip this param and undo the esp setting
				$esp{$module} = 0;
			} else {
				$parameter{$id} = $n;
			}
		} else {
			$esp{$module} = "$cmd in parameter";
		}
	}
}

sub instances {
	local($level) = @_;
	$instance_type = getid($level);
	while(($cmd, $nargs, $value, $detail) = get($level)) {
		return if $esp{$module};
		next if $cmd eq "delay";
		if ($cmd eq "instance") {
			$instance_name = getid($level+1);
			# instance names should be unique, but let's be safer
			$instance_name = "$module/$instance_name";
			$instances{$module} .= " $instance_name";
			$instance_type{$instance_name} = $instance_type;
			while(($cmd, $nargs, $value, $detail) = get($level+1)) {
				return if $esp{$module};
				if ($cmd eq "dot") {
					# first dot arg is id
					local ($port) = getid($level+2);
					# second is id/bit/range/concat/multiconcat
					next unless
						(($cmd, $nargs, $value, $detail) = get($level+2));
					getaport($level+3);
				} else {
					local $port = "-unnamed-";
					getaport($level+2);
				}

			}
			next;
		}
		$esp{$module} = "$cmd in instance";
	}
}

sub getaport {
	local ($level) = @_;
	if ($cmd eq "id") {
		connectport($port, "$value -1 -1");
	} elsif ($cmd eq "bit") {
		local($id, $bit) = getbit($level);
		connectport($port, "$id $bit $bit");
	} elsif ($cmd eq "range") {
		local($id, $from, $to) = getrange3($level);
		connectport($port, "$id $from $to");
	} elsif ($cmd eq "concat") {
		local($stuff) = getconcat($level);
		connectport($port, $stuff);
	} elsif ($cmd eq "multiconcat") {
		local($stuff) = getmulticoncat($level);
		connectport($port, $stuff);
	} elsif ($cmd eq "num") {
		local $stuff = $value ? "vdd" : "gnd";
		connectport($port, "$stuff -1 -1");
	} else {
		die "$module: $cmd unexpected in port\n";
	}
}

sub connectport {
	local($port, $stuff) = @_;
	local($n) = 0 + split(' ', $stuff);
	die "internal error 73843\n" if $n < 3;
	if ($n == 3) {
		$connections{$instance_name} .= "/$port -1 -1 = $stuff";
	} else {
		local($gen) = gen();
		$connections{$instance_name} .= "/$port -1 -1 = $gen";
		assign($gen, $stuff);
	}
}

sub gen {
	$gencount++;
	return "generated$gencount -1 -1";
}

sub netORassign {
	local($level) = @_;
	while(($cmd, $nargs, $value, $detail) = (get($level))) {
		if ($cmd eq "assign" || $cmd eq "nbassign") {
			local($lvalue) = get1concatable($level+1);
			get($level+1);  # skip timing control
			local($rvalue) = get1concatable($level+1);
			return if $esp{$module};
			assign($lvalue, $rvalue);
		}
	}
}

sub assign {
	local($lhs, $rhs) = @_;
	if (splitcount($lhs) > 3 && splitcount($rhs) > 3) {
		local($gen) = gen();
		assign($gen, $rhs);
		assign($lhs, $gen);
		return;
	}
	$assigns{$module} .= "/$lhs = $rhs";
}

sub port {
	local($direction, $level) = @_;
	local($range1, $range2) = (-1, -1);
	local($port);
	while(($cmd, $nargs, $value, $detail) = (get($level))) {
		return if $esp{$module};
		if ($cmd eq "range") {
			($range1,$range2) = getrange2($level+1);
			next;
		}
		if ($cmd eq "id") {
			$port = $value;
			$portcount{$module}++;
			$direction{"$module $port"} = $direction;
			$fullname{"$module $port"} = busify($port, $range1, $range2);
			next;
		}
		$esp{$module} = "$cmd in port";
	}

}

sub pass2 {
	print "looking for existing sue icons\n";
	foreach $module (@modules) {
		get_existing_sue_icon($module);
	}
	print "thinking\n";
	foreach $module (@modules) {
		fiddle_with_ports() unless $existing{$module};
	}
	foreach $module (@modules) {
		calculate_icon_width();
	}
	calculate_assign_xs();
	foreach $module (@modules) {
		calculate_position_of_ports() unless $existing{$module};
	}
	foreach $module (@modules) {
		write_sue_file() unless $existing{$module};
	}
}

sub get_existing_sue_icon {
	my($module) = @_;
	local(%portcheck);
	open(IN, "$module.sue") || return;
	my($xmin, $xmax, $ymin, $ymax);
	while (<IN>) {
		next unless
			/^\s*icon_term -type \S+ -origin {(\S+) (\S+)} -name (\S+)$/;
		my($x, $y, $name, $fullname) = ($1, $2, $3, $3);
		$name = $1 if $name =~ /^{(.+)\[/;
		$portcheck{$name} = 1;
		my($mp) = "$module $name";
		$fullname{$mp} = $fullname;
		$xnn{$mp} = $xport{$mp} = $x;
		$ynn{$mp} = $yport{$mp} = $y;
		$xmin = defined($xmin) ? &min($xmin, $x) : $x;
		$xmax = defined($xmax) ? &max($xmax, $x) : $x;
		$ymin = defined($ymin) ? &min($ymin, $y) : $y;
		$ymax = defined($ymax) ? &max($ymax, $y) : $y;
	}
	if (portsok($module)) {
		print "using $module.sue\n";
		$existing{$module} = 1;
		$xmin{$module} = $xmin;
		$ymin{$module} = $ymin - 20;
		$icon_height{$module} = $ymax - $ymin + 60;
	} else {
		print "rejecting $module.sue (port mismatch)\n";
	}
	close(IN);
}

sub portsok {
	foreach $name (split(' ', $portorder{$module})) {
		$portcheck{$name} += 2;
	}
	foreach $name (keys %portcheck) {
		return 0 unless $portcheck{$name} == 3;
	}
	return 1;
}

sub fiddle_with_ports {
	# If portorder doesn't agree in count with portcount, then
	# we were unable to decode the input/output/inout commands,
	# so we don't know directions and ranges, so forget it.
	if (splitcount($portorder{$module}) != $portcount{$module}) {
		$portorder{$module} = "";
		$portcount{$module} = 0;
		$portproblem = 1;
	}
}

sub splitcount {
	local($s) = @_;
	return 0 + split(' ', $s);
}

sub portsof {
	local($module) = @_;
	return split(' ', $portorder{$module});
}

sub calculate_icon_width {
	$max{"input"} = $max{"output"} = 0;
	foreach $port (portsof($module)) {
		local($direction) = $direction{"$module $port"};
		$direction = $inoutmap{$direction};
		$max{$direction} = max($max{$direction}, length($port));
	}
	$icon_width = max($icon_width, 20 * ($max{"input"} + $max{"output"} + 5));
}

sub calculate_assign_xs {
	$xal = int(0.5 * $icon_width);
	$xam = int(1.0 * $icon_width);
	$xar = int(1.5 * $icon_width);
}

sub calculate_position_of_ports {
	$ypos{"input"} = 20;
	$ypos{"output"} = 20;
	$xpos{"input"} = 0;
	$xpos{"output"} = $icon_width;
	$xlabel{"input"} = 20;
	$xlabel{"output"} = $icon_width - 20;
	$xnn{"input"} = int(-$icon_width/4);
	$xnn{"output"} = int(1.25 * $icon_width);
	foreach $port (portsof($module)) {
		local($mp) = "$module $port";
		local($direction) = $direction{$mp};
		$direction = $inoutmap{$direction};
		$xport{$mp} = $xpos{$direction};
		$yport{$mp} = $ypos{$direction};
		$xnn{$mp} = $xnn{$direction};
		$ynn{$mp} = $ypos{$direction};
		$ypos{$direction} += 20;
	}
	$icon_footer{$module} = max($ypos{"input"}, $ypos{"output"});
	$icon_height{$module} = $icon_footer{$module} + 20;
}

sub write_sue_file {
	print "writing file $module.sue (";
	if (!$esp{$module}) {
		print "structural";
	} else {
		print !$portproblem ? "behavioral" : $espmess2;
		print ": $esp{$module}"
	}
	print ")\n";
	open(OUT, ">$module.sue") || die "can't write $module.sue\n";
	print OUT "# generated by verilog_to_sue\n\n";
	print OUT "proc ICON_$module args {\n";
	write_icon_body();
	write_icon_footer();
	print OUT "}\n\n";
	print OUT "proc SCHEMATIC_$module {} {\n";
	if ($esp{$module}) {
		local ($m) = !$portproblem ? $espmess : $espmess2;
		print OUT "  make_text -origin {0 0} -text {$m}\n";
	} else {
		write_schematic();
	}
	print OUT "}\n";
	close(OUT);
}

sub write_icon_body {
	print OUT "  icon_setup \$args {{origin {0 0}} {orient R0} {name {}} {M {}}}\n";
	foreach $port (portsof($module)) {
		local($x, $y, $direction, $anchor);
		$direction = $direction{"$module $port"};
		$x = $xport{"$module $port"};
		$y = $yport{"$module $port"};
		$port = $fullname{"$module $port"};
		print OUT "  icon_term -type $direction -origin {$x $y} -name $port\n";
		$x = $xlabel{$inoutmap{$direction}};
		$anchor = " -anchor e" if $inoutmap{$direction} eq "output";
		print OUT "  icon_property -origin {$x $y}$anchor -label $port\n";
	}
}

sub write_icon_footer() {
	local($y);
	$y = $icon_footer{$module};
	print OUT "  icon_property -origin {20 $y} -size large -label $module\n";
	$y = $icon_height{$module};
	print OUT "  icon_line 0 0 $icon_width 0 $icon_width $y 0 $y 0 0\n";
	$y += 20;
	print OUT "  icon_property -origin {0 $y} -type user -name name\n";
	$y += 20;
	print OUT "  icon_property -origin {0 $y} -type user -name M\n";
}

sub write_schematic {
	local($schematic_height) = calculate_schematic_height();
	local($x, $y, $sbottom) = (0, 0, 0);
	foreach $instance (instancesin($module)) {
		local($instance_type) = $instance_type{$instance};
		local $realname = substr($instance, length($module)+1);
		my($x8, $y8) = ($x, $y);
		if ($existing{$instance_type}) {
			$x8 -= $xmin{$instance_type};
			$y8 -= $ymin{$instance_type};
		}
		print OUT "  make $instance_type -name $realname -origin {$x8 $y8}\n";
		local @po = portsof($instance_type);
		if ($portproblem) { $connections{$instance} = ""; }
		foreach $connection (split('/', substr($connections{$instance}, 1))) {
			local(@f) = split(' ', $connection);
			next if @f == 0;
			die "$module: funny connection\n" unless @f == 7;
			local($formal, $f1, $f2, $eq, $actual, $a1, $a2) = @f;
			$formal = shift(@po) if $formal eq "-unnamed-";
			$actual = busify($actual, $a1, $a2);
			local($mf) = ("$instance_type $formal");
			local($x1) = ($x + $xport{$mf});
			local($y1) = ($y + $yport{$mf});
			local($x2) = ($x + $xnn{$mf});
			local($y2) = ($y1);
			if ($existing{$instance_type}) {
				$x2 -= $xmin{$instance_type};
				$y2 -= $ymin{$instance_type};
			} else {
				print OUT "  make_wire $x1 $y1 $x2 $y2\n"
			}
			print OUT "  make name_net_s -name $actual -origin {$x2 $y2}\n";
		}
		nudgey($icon_height{$instance_type});
	}
	foreach $assign (assignsin($module)) {
		local($x1) = $x + $xnn{"input"};
		local($x3) = $x + $xnn{"output"};
		local($x2) = int(($x1+$x3)/2);
		local($lhs, $rhs) = split('=', $assign);
		local(@lhs) = split(' ', $lhs);
		local(@rhs) = split(' ', $rhs);
		die "internal error 8371\n" unless ((@lhs > 0) && ((@lhs % 3) == 0));
		die "internal error 8372\n" unless ((@rhs > 0) && ((@rhs % 3) == 0));
		die "internal error 3383\n" if @lsh > 3 && @rhs > 3;
		local $nl = @lhs / 3;
		local $nr = @rhs / 3;
		local $nm = max($nl, $nr);
		local($ymid) = $y + (($nm - 1) * $ybci) / 2;
		if ($nr >= $nl) {
			print OUT "  generate bus_combine bus_combine$nr -ninputs $nr\n";
			print OUT "  make bus_combine$nr -orient RY -origin {$x2 $ymid}\n";
		} else {
			print OUT "  generate bus_split bus_split$nl -noutputs $nl\n";
			print OUT "  make bus_split$nl -orient RY -origin {$x2 $ymid}\n";
		}
		local($i);
		# combine(@lhs, $x3, $ymid, $x2+20);
		for ($i = 0; $i < $nl; $i++) {
			buspins(@lhs[$i*3..$i*3+2], $x3,
				$nl == 1 ? $ymid : $y+$i*$ybci, $x2+20);
		}
		for ($i = 0; $i < $nr; $i++) {
			buspins(@rhs[$i*3..$i*3+2], $x1,
				$nr == 1 ? $ymid : $y+$i*$ybci, $x2-10);
		}
		nudgey($nm * $ybci);
	}
	$x{"input"} = -$icon_width;
	$x{"output"} = $y == 0 ? $x : $x + 2 * $icon_width;
	$y{"input"} = $y{"output"} = 0;
	foreach $port (portsof($module)) {
		local($direction) = ($direction{"$module $port"});
		$x = $x{$inoutmap{$direction}};
		$y = $y{$inoutmap{$direction}};
		$port = $fullname{"$module $port"};
		print OUT "  make $direction -name $port -origin {$x $y}\n";
		$y{$direction} += 20;
	}
}

sub buspins {
	local($name, $r1, $r2, $x, $y, $wx) = @_;
	$name = busify($name, $r1, $r2);
	print OUT "  make_wire $wx $y $x $y\n";
	print OUT "  make name_net_s -name $name -origin {$x $y}\n";
}

sub nudgey {
	local($dy) =  @_;
	$y += $dy + $vsbi;
	$sbottom = max($sbottom, $y);
	if ($y >= $schematic_height) {
		$x += 2 * $icon_width;
		$y = 0;
	}
}

sub assignsin {
	local($module) = @_;
	return split('/', substr($assigns{$module}, 1));
}

sub calculate_schematic_height {
	local ($total_y);
	foreach $instance (instancesin($module)) {
		$total_y += $icon_height{$instance} + $vsbi;
	}
	foreach $assign (assignsin($module)) {
		local($lhs, $rhs) = split('=', $assign);
		local($n) = max(splitcount($lhs), splitcount($rhs)) / 3;
		$total_y += $n * $ybci;
	}
	return sqrt($total_y * 2 * $icon_width);
}

sub instancesin {
	local($module) = @_;
	return split(' ', $instances{$module});
}

sub min {
	local($a, $b) = @_;
	return $a < $b ? $a : $b;
}

sub max {
	local($a, $b) = @_;
	return $a > $b ? $a : $b;
}

sub busify {
	local($name, $range1, $range2) = @_;
	return $name if $range1 eq "-1" && $range2 eq "-1";
	return "{$name\[$range1]}" if $range1 eq $range2;
	return "{$name\[$range1:$range2]}";
}

sub getid {
	local($level) = @_;
	local($cmd, $nargs, $value, $detail) = get($level);
	$esp{$module} = "$cmd instead of id" if $cmd ne "id";
	return $value;
}

sub getnum {
	local($level) = @_;
	local($cmd, $nargs, $value, $detail) = get($level);
	if ($cmd eq "num") {
		$esp{$module} = "messy number" if $value ne $detail;
		return $value;
	} elsif ($cmd eq "b+") {
		local ($a) = getnum($level+1);
		local ($b) = getnum($level+1);
		return $a + $b;
	} elsif ($cmd eq "b-") {
		local ($a) = getnum($level+1);
		local ($b) = getnum($level+1);
		return $a - $b;
	} elsif ($cmd eq "id") {
		if ($parameter{$value}) {
			return $parameter{$value};
		} else {
			$esp{$module} = "missing parameter";
		}
	} else {
		$esp{$module} = "$cmd for number";
	}
	return 0;
}

sub getbit {
	local ($level) = @_;
	local $id = getid($level);
	local $num = getnum($level);
	return($id, $num);
}

sub getrange2 {
	local ($level) = @_;
	local $from = getnum($level);
	local $to = getnum($level);
	return ($from, $to);
}

sub getrange3 {
	local ($level) = @_;
	local $name = getid($level);
	local $from = getnum($level);
	local $to = getnum($level);
	return ($name, $from, $to);
}

sub get1concatable {
	local ($level) = @_;
	local($r);
	($cmd, $nargs, $value, $detail) = get($level);
	if ($cmd eq "id") {
		$r .= " $value -1 -1";
	} elsif ($cmd eq "bit") {
		local($id, $bit) = getbit($level+1);
		$r .= " $id $bit $bit";
	} elsif ($cmd eq "range") {
		local($id, $from, $to) = getrange3($level+1);
		$r .= " $id $from $to";
	} elsif ($cmd eq "concat") {
		$r .= getconcat($level+1);
	} elsif ($cmd eq "multiconcat") {
		$r .= getmulticoncat($level+1);
	} elsif ($cmd eq "num") {
		local $stuff = $value ? "vdd" : "gnd";
		$r .= " $stuff -1 -1";
	} else {
		$esp{$module} = "$cmd for assign";
	}
	return $r;
}

sub getconcat {
	local ($level) = @_;
	local($r);
	while(($cmd, $nargs, $value, $detail) = get($level)) {
		if ($cmd eq "id") {
			$r .= " $value -1 -1";
		} elsif ($cmd eq "bit") {
			local($id, $bit) = getbit($level+1);
			$r .= " $id $bit $bit";
		} elsif ($cmd eq "range") {
			local($id, $from, $to) = getrange3($level+1);
			$r .= " $id $from $to";
		} elsif ($cmd eq "concat") {
			$r .= getconcat($level+1);
		} elsif ($cmd eq "multiconcat") {
			$r .= getmulticoncat($level+1);
		} elsif ($cmd eq "num") {
			local $stuff = $value ? "vdd" : "gnd";
			$r .= " $stuff -1 -1";
		} else {
			$esp{$module} = "$cmd for concat";
		}
	}
	return $r;
}

sub getmulticoncat {
	local ($level) = @_;
	local($n) = getnum($level);
	($cmd, $nargs, $value, $detail) = get($level);
	$esp{$module} = "$cmd for concat" if $cmd ne "concat";
	local($stuff) = getconcat($level+1);
	return $stuff x $n;
}

sub pass3 {
	# rebuild module data because we may have lost instances in behavioral code
	open(IN, "$vpp @ARGV | $hdl|") || die "trouble running parser\n";
	@modules = ();
	set("IN");
	while (($cmd, $nargs, $value, $detail) = (get(0))) {
		next unless $cmd eq "module";
		$module = getid(1);
		$instances{$module} = "";
		push(@modules, $module);
		while(($cmd, $nargs, $value, $detail) = (get(1))) {
			next unless $cmd eq "instances";
			local ($instance_type) = (getid(2));;
			while(($cmd, $nargs, $value, $detail) = get(2)) {
				next unless $cmd eq "instance";
				local ($instance_name) = (getid(3));
				# instance names should be unique, but let's be safer
				$instance_name = "$module/$instance_name";
				$instances{$module} .= " $instance_name";
				$instance_type{$instance_name} = $instance_type;
			}
		}
	}
	close(IN);

	print "\nhierarchy:\n\n";
	local (%printed, $top, $n);
	while (@modules) {
		$top = &get_top_level;
		return unless $top;
		$n++;
		print_hier($top, 1, 0, "$n");
	}
}

sub get_top_level {
	cand: foreach $candidate (@modules) {
		next if $printed{$candidate};
		foreach $module (@modules) {
			next if $module eq $candidate;
			foreach $instance (instancesin($module)) {
				next cand if $instance_type{$instance} eq $candidate;
			}
		}
		return $candidate;
	}
	return 0;
}

sub print_hier {
	local ($module, $instances, $tab, $id) = @_;
	print "  " x $tab;
	print "$module ($id";
	print " - $instances instances" if $instances > 1;
	print " - see $printed{$module}" if $printed{$module};
	print ")\n";
	return if $printed{$module};
	$printed{$module} = $id;

	local (%instamatic);
	foreach $instance (instancesin($module)) {
		local ($i) = ($instance_type{$instance});
		$instamatic{$i}++;
	}
	local ($n);
	foreach $i (keys %instamatic) {
		$n++;
		print_hier($i, $instamatic{$i}, $tab+1, "$id.$n");
	}
}

sub set {
	($hdl_reader_thing_to_read) = @_;
	@hdl_reader_levels = (-1);
}

sub get {
	local($level) = @_;
	local($line, @f);
	while ($level < @hdl_reader_levels-1) {
		hdl_reader_get0();
		return () unless $line;
	}
	return () if $level > @hdl_reader_levels-1;
	hdl_reader_get0();
	return () unless $line;
	$f[2] = $f[3] = $1 if $line =~ /^str \S+ (.+)/;
	$f[3] = $1 if $line =~ /^num \S+ \S+ (.+)/;
	$f[3] = $f[2] if $f[1] eq "id";
	return ($f[0], $f[1], $f[2], $f[3]);
}

sub hdl_reader_get0 {
	$line = <$hdl_reader_thing_to_read>;
	return () unless $line;
	@f = (split(' ', $line));
	push(@hdl_reader_levels, pop(@hdl_reader_levels) - 1);
	push(@hdl_reader_levels, $f[1]);
	while (1) {
		local($top) = (pop(@hdl_reader_levels));
		next unless $top;
		push(@hdl_reader_levels, $top);
		last;
	}
}
