use v6;
use Bailador;
use HTTP::Server::Simple;

my $latest;
my @titles;

sub scan {
	$latest = 0;
	for dir('posts') -> $file {
		$latest++ if !$file.basename.starts-with('.') && $file.basename.ends-with('.html');
	}
	@titles = Nil;
	loop (my $i = $latest; $i > 0; $i--) {
		@titles[$latest - $i] = "posts/$i.html".IO.lines: 1;
	}
}

Supply.interval(1200).tap: { scan(); }

get '/' => sub {
	template 'index.tmpl', @titles
}

get '/list' => sub {
	template 'list.tmpl', @titles
}

get / ^ '/blog/' (.+) $ / => sub ($post) {
	template 'blog.tmpl',{ post => $post }
}

baile();
