# Edited from https://github.com/savonet/liquidsoap/blob/master/scripts/utils.liq#L418

def dps_crossfade (~start_next=5.,~fade_in=3.,
                     ~fade_out=3., ~width=2., 
                     ~high = -20., ~medium = -32.,
                     ~margin = 4., ~conservative=true,s)

  fade.out = fade.out(type="sin",duration=fade_out)
  fade.in  = fade.in(type="sin",duration=fade_in)
  add = fun (a,b) -> add(normalize=false,[b,a])
  log = log(label="smart_crossfade")

  def transition(a,b,ma,mb,sa,sb)

    if ma["dps_type"] == "2" or mb["dps_type"] == "2" then
      log("Old or new file is a jingle: sequenced transition.")
      sequence([sa, sb])
    elsif
      # If A and B and not too loud and close, 
      # fully cross-fade them.
      a <= medium and 
      b <= medium and 
      abs(a - b) <= margin
    then
      log("Transition: crossed, fade-in, fade-out.")
      add(fade.out(sa),fade.in(sb))

    elsif
      # If B is significantly louder than A, 
      # only fade-out A.
      # We don't want to fade almost silent things, 
      # ask for >medium.
      b >= a + margin and a >= medium and b <= high
    then
      log("Transition: crossed, fade-out.")
      add(fade.out(sa),sb)

    elsif
      # Do not fade if it's already very low.
      b >= a + margin and a <= medium and b <= high
    then
      log("Transition: crossed, no fade.")
      add(sa,sb)

    elsif
      # Opposite as the previous one.
      a >= b + margin and b >= medium and a <= high
    then
      log("Transition: crossed, fade-in.")
      add(sa,fade.in(sb))

    # What to do with a loud end and 
    # a quiet beginning ?
    # A good idea is to use a jingle to separate 
    # the two tracks, but that's another story.

    else
      # Otherwise, A and B are just too loud 
      # to overlap nicely, or the difference 
      # between them is too large and 
      # overlapping would completely mask one 
      # of them.
      log("No transition: just sequencing.")
      sequence([sa, sb])
    end
  end

  smart_cross(width=width, duration=start_next, 
              conservative=conservative,
              transition,s)
end