s@<p>CUSTOMTAGBEGINCOMMENTARY</p>@<div class=commentary>@;
s@CUSTOMTAGBEGINCOMMENTARY</p>@<div class=commentary>@;
s@<p>CUSTOMTAGENDCOMMENTARY</p>@</div>@;
s@CUSTOMTAGBEGINTITLE@<div class=title>@;
s@CUSTOMTAGENDTITLE@</div>@;
s@CUSTOMTAGBEGINLARGE@<h1>@;
s@CUSTOMTAGENDLARGE@</h1>@;
s@CUSTOMTAGBEGINAUTHOR@<h3>@;
s@CUSTOMTAGENDAUTHOR@</h3>@;
s@src=\"tmp.latest[/]+@src=\"@;
s@src=\"tmp.draft[/]+@src=\"@;
s@<div id="refs"@<h2>Bibliography</h2><div id="refs"@;
s@<div id="ref-(.*?)">@<div id="ref-$1">[$1]@;
s@data-cites="([\w\-\:]+)(.*?)">.*?</span>@data-cites="$1$2"><a href="#ref-$1">[$1$2]</a></span>@g;
s@\$\\mbox\{\\em (\w+)}@<em>$1</em>@g;
s@\\mbox\{\\em\s+(\w+)\}\$@<em>$1</em>@g;
s@\\mbox\{\\em\s*$\s*(\w+)\}\$@<em>$1</em>@g;
s@\$?\{\\em\s+(\w+)\}\$?@<em>$1</em>@gm;
# Line break on em
if ($ml_em == 1) {s@^\s*(\w+)\}\$@$1</em>@g;$ml_em=0;}
if (s@\{\\em\s*$@<em>@g) {$ml_em=1;}

s@HYPERREF\[.*?\]@@g;
if ($tmp == 1) {s@^\s*(\w+)\}\$@$1</em>@}
if (s@\\mbox\{\\em$@<em>@) {$tmp = 1;} else {$tmp = 0}
