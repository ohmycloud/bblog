use v6;

use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Text::VimColour;
use Template6;

my $latest;
my @titles;

my $t6 = Template6.new;
$t6.add-path: 'views';
$t6.add-path: 'include';

sub scan {
	$latest = 0;
	for dir('posts') -> $file {
		$latest++ if !$file.basename.starts-with('.') && $file.basename.ends-with('.html');
	}
	@titles = ();
	loop (my $i = $latest; $i > 0; $i--) {
		my %h = index => $i, title => "posts/$i.html".IO.lines[0];
		@titles.push(%h);
	}
}

Supply.interval(1200).tap: { scan(); }

my $application = route {
	get -> {
		my @clipped_titles;
		if @titles.elems < 4 {
			@clipped_titles = @titles;
		} else {
			@clipped_titles = @titles[^3];
		}
		content 'text/html', $t6.process('index', :titles(@clipped_titles));
	}

	get -> 'list' {
		content 'text/html', $t6.process('list', :titles(@titles));
	}

	get -> 'blog', $post {
		my $content;
		if "posts/$post.html".IO.e {
			$content = slurp "posts/$post.html";
		} else {
			$content = "Post not found.";
		}
		content 'text/html', $t6.process('blog', :content($content));
	}
}

my Cro::Service $service = Cro::HTTP::Server.new(
	:host('127.0.0.1'), :port(3000), :$application
);

$service.start;

react whenever signal(SIGINT) {
	$service.stop;
	exit;
}
