package Ace::Graphics::Glyph::segments;
# package to use for drawing anything that is interrupted
# (has the segment() method)

use strict;
use vars '@ISA';
@ISA = 'Ace::Graphics::Glyph';

use constant GRAY  => 'lightgrey';

# override right to allow for label
sub _right {
  my $self = shift;
  my $left = $self->left;
  my $val = $self->SUPER::_right(@_);

  if ($self->option('label') && (my $description = $self->description)) {
    my $description_width = $self->font->width * length $self->description;
    $val = $left + $description_width if $left + $description_width > $val;
  }
  $val;
}

# override the bottom method in order to provide extra room for
# the label
# sub _height {
#   my $self = shift;
#   my $val = $self->SUPER::_height(@_);
#   $val += $self->labelheight if $self->option('label') && $self->description;
#   $val;
# }

# override draw method
sub draw {
  my $self = shift;

  # bail out if this isn't the right kind of feature
  return $self->SUPER::draw(@_) unless $self->feature->can('segments');

  # get parameters
  my $gd = shift;
  my ($x1,$y1,$x2,$y2) = $self->calculate_boundaries(@_);

  my $gray = $self->color(GRAY);

  my (@segments,@boxes,@skips);
  @segments   = $self->feature->merged_segments;

  for (my $i=0; $i < @segments; $i++) {
    my ($start,$stop) = ($self->map_pt($segments[$i]->start),
			 $self->map_pt($segments[$i]->stop));

    # probably unnecessary, but we do it out of paranaoia
    ($start,$stop) = ($stop,$start) if $start > $stop;

    push @boxes,[$start,$stop];

    if (my $next_segment = $segments[$i+1]) {
      my ($next_start,$next_stop) = ($self->map_pt($next_segment->start),
				     $self->map_pt($next_segment->stop));
      # probably unnecessary, but we do it out of paranaoia
      ($next_start,$next_stop) = ($next_stop,$next_start) if $next_start > $next_stop;

      # fudge boxes that are within two pixels of each other
      if ($next_start - $stop < 2) {
	$boxes[-1][1] = $next_start;
      }
      push @skips,[$stop+1,$next_start-1];
    }
  }

  my $fg     = $self->fgcolor;
  my $fill   = $self->fillcolor;
  my $center = ($y1 + $y2)/2;

  # each segment becomes a box
  for my $e (@boxes) {
    my @rect = ($e->[0],$y1,$e->[1],$y2);
    $self->filled_box($gd,@rect);
  }

  # each skip becomes a simple line
  for my $i (@skips) {
    next unless $i->[1] - $i->[0] >= 1;
    $gd->line($i->[0],$center,$i->[1],$center,$gray);
  }

  # draw label
  $self->draw_label($gd,@_) if $self->option('label');
}

sub description {
  my $self = shift;
  $self->feature->info;
}

1;
