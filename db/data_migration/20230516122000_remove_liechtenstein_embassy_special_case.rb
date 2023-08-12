location = WorldLocation.find_by!(slug: "liechtenstein")
organisation = WorldwideOrganisation.find_by!(slug: "british-embassy-liechtenstein")
organisation.world_locations -= [location]

organisation = WorldwideOrganisation.find_by!(slug: "british-embassy-berne")
organisation.world_locations += [location] unless organisation.world_locations.include?(location)

location.reload

embassy = Embassy.new(location)
unless embassy.organisations_with_embassy_offices == [organisation]
  msg = <<~END_MESSAGE
    Expected #{location} to have a single embassy organisation of #{organisation.slug}
    But actually contains #{embassy.organisations_with_embassy_offices.map(&:slug)}
  END_MESSAGE
  puts msg
end
