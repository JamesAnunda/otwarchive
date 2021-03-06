Given /^mock websites with no content$/ do
  WebMock.disable_net_connect!
  WebMock.stub_request(:head, "http://example.org/200")
  WebMock.stub_request(:head, "http://example.org/301").to_return(status: 301)
  WebMock.stub_request(:head, "http://example.org/404").to_return(status: 404)
end

Given /^I have a bookmark for "([^\"]*)"$/ do |title|
  step %{I start a new bookmark for "#{title}"}
  fill_in("bookmark_tag_string", with: DEFAULT_BOOKMARK_TAGS)
  step %{I press "Create"}
  step %{all indexing jobs have been run}
end

Given /^I have a bookmark of a deleted work$/ do
  title = "Deleted Work For Bookmarking"
  step %{I start a new bookmark for "#{title}"}
  fill_in("bookmark_tag_string", with: DEFAULT_BOOKMARK_TAGS)
  step %{I press "Create"}
  work = Work.find_by(title: title)
  work.destroy
  step %{all indexing jobs have been run}
end

Given /^I have bookmarks to search$/ do
  # set up a user
  user1 = FactoryGirl.create(:user, login: "testuser")

  # set up the pseuds
  pseud1 = FactoryGirl.create(:pseud, name: "testy", user_id: user1.id)
  pseud2 = FactoryGirl.create(:pseud, name: "tester_pseud", user_id: user1.id)

  # set up a tag
  freeform1 = FactoryGirl.create(:freeform, name: "classic")
  freeform2 = FactoryGirl.create(:freeform, name: "rare")

  # set up some works
  work1 = FactoryGirl.create(:posted_work, title: "First work", freeform_string: freeform2.name)
  work2 = FactoryGirl.create(:posted_work, title: "second work")
  work3 = FactoryGirl.create(:posted_work, title: "third work")
  work4 = FactoryGirl.create(:posted_work, title: "fourth")
  work5 = FactoryGirl.create(:posted_work, title: "fifth")

  # set up an external work
  external1 = FactoryGirl.create(:external_work, title: "Skies Grown Darker")

  # set up the bookmarks
  FactoryGirl.create(:bookmark,
                     bookmarkable_id: work1.id,
                     pseud_id: user1.default_pseud.id,
                     rec: true)

  FactoryGirl.create(:bookmark,
                     bookmarkable_id: work2.id,
                     pseud_id: user1.default_pseud.id,
                     tag_string: freeform2.name)

  FactoryGirl.create(:bookmark,
                     bookmarkable_id: work3.id,
                     pseud_id: user1.default_pseud.id,
                     tag_string: freeform1.name)

  FactoryGirl.create(:bookmark, bookmarkable_id: work4.id, pseud_id: pseud1.id)

  FactoryGirl.create(:bookmark,
                     bookmarkable_id: work5.id,
                     pseud_id: pseud2.id,
                     notes: "Left me with a broken heart")

  FactoryGirl.create(:bookmark,
                     bookmarkable_id: external1.id,
                     bookmarkable_type: "ExternalWork",
                     pseud_id: pseud2.id,
                     notes: "I enjoyed this")

  step %{all indexing jobs have been run}
end

Given /^I have bookmarks to search by any field$/ do
  work1 = FactoryGirl.create(:posted_work, title: "Comfort", freeform_string: "hurt a little comfort but only so much")
  work2 = FactoryGirl.create(:posted_work, title: "Hurt and that's it")
  work3 = FactoryGirl.create(:posted_work, title: "Fluff")

  FactoryGirl.create(:bookmark, bookmarkable_id: work1.id, notes: "whatever")
  FactoryGirl.create(:bookmark, bookmarkable_id: work2.id, tag_string: "more please")
  FactoryGirl.create(:bookmark, bookmarkable_id: work3.id, notes: "more please")

  step %{all indexing jobs have been run}
end

Given /^I have bookmarks to search by dates$/ do
  work1 = nil
  Timecop.freeze(901.days.ago) do
    work1 = FactoryGirl.create(:posted_work, title: "Old work")
    FactoryGirl.create(:bookmark, bookmarkable_id: work1.id, notes: "Old bookmark of old work")
  end
  FactoryGirl.create(:bookmark, bookmarkable_id: work1.id, notes: "New bookmark of old work")

  work2 = FactoryGirl.create(:posted_work, title: "New work")
  FactoryGirl.create(:bookmark, bookmarkable_id: work2.id, notes: "New bookmark of new work")

  step %{all indexing jobs have been run}
end

When /^I bookmark the work "(.*?)"(?: as "(.*?)")?(?: with the note "(.*?)")?(?: with the tags "(.*?)")?$/ do |title, pseud, note, tags|
  step %{I start a new bookmark for "#{title}"}
  select(pseud, from: "bookmark_pseud_id") unless pseud.nil?
  fill_in("bookmark_notes", with: note) unless note.nil?
  fill_in("bookmark_tag_string", with: tags) unless tags.nil?
  click_button("Create")
  step %{all indexing jobs have been run}
end

When /^I bookmark the series "([^\"]*)"$/ do |series_title|
  series = Series.find_by(title: series_title)
  visit series_path(series)
  click_link("Bookmark Series")
  click_button("Create")
  step %{all indexing jobs have been run}
end

When /^I start a new bookmark for "([^\"]*)"$/ do |title|
  step %{I open the bookmarkable work "#{title}"}
  click_link("Bookmark")
end

When /^I start a new bookmark$/ do
  step %{I start a new bookmark for "#{DEFAULT_TITLE}"}
end

When /^I bookmark the works "([^\"]*)"$/ do |worklist|
  worklist.split(/, ?/).each do |work_title|
    step %{I bookmark the work "#{work_title}"}
  end
end

When /^I edit the bookmark for "([^\"]*)"$/ do |title|
  step %{I open the bookmarkable work "#{title}"}
  click_link("Edit Bookmark")
end

When /^I open a bookmarkable work$/ do
  step %{I open the bookmarkable work "#{DEFAULT_TITLE}"}
end

When /^I open the bookmarkable work "([^\"]*)"$/ do |title|
  work = Work.find_by(title: title)
  if !work
    step %{I post the work "#{title}"}
    work = Work.find_by(title: title)
  end
  visit work_path(work)
end

When /^I add my bookmark to the collection "([^\"]*)"$/ do |collection_name|
  step %{I follow "Add To Collection"}
    fill_in("collection_names", with: "#{collection_name}")
    click_button("Add")
end

When /^I rec the current work$/ do
  click_link("Bookmark")
  check("bookmark_rec")
  click_button("Create")
  step %{all indexing jobs have been run}
end

When(/^I attempt to create a bookmark of "([^"]*)" with a pseud that is not mine$/) do |work|
  step %{I am logged in as "commenter"}
  step %{I start a new bookmark for "#{work}"}
  pseud_id = User.first.pseuds.first.id
  find("#bookmark_pseud_id", visible: false).set(pseud_id)
  click_button "Create"
end

When(/^I attempt to transfer my bookmark of "([^"]*)" to a pseud that is not mine$/) do |work|
  step %{the user "not_the_bookmarker" exists and is activated}
  step %{I edit the bookmark for "#{work}"}
  pseud_id = User.find_by(login: "not_the_bookmarker").pseuds.first.id
  find("#bookmark_pseud_id", visible: false).set(pseud_id)
  click_button "Edit"
end

Then /^the bookmark on "([^\"]*)" should have tag "([^\"]*)"$$/ do |title, tag|
  work = Work.find_by(title: title)
  bookmark = work.bookmarks.first
  bookmark.reload
  bookmark.tags.collect(&:name).include?(tag)
end
Then /^the ([\d]+)(?:st|nd|rd|th) bookmark result should contain "([^"]*)"$/ do |n, text|
  selector = "ol.bookmark > li:nth-of-type(#{n})"
  with_scope(selector) do
    page.should have_content(text)
  end
end

Then /^the cache of the bookmark on "([^\"]*)" should expire after I edit the bookmark tags$/ do |title|
  work = Work.find_by(title: title)
  bookmark = work.bookmarks.first
  orig_cache_key = bookmark.cache_key
  Kernel::sleep 1
  visit edit_bookmark_path(bookmark)
  fill_in("bookmark_tag_string", with: "New Tag")
  click_button("Update")
  bookmark.reload
  assert orig_cache_key != bookmark.cache_key, "Cache key #{orig_cache_key} matches #{bookmark.cache_key}."
end

Then /^the cache of the bookmark on "([^\"]*)" should not expire if I have not edited the bookmark$/ do |title|
  work = Work.find_by(title: title)
  bookmark = work.bookmarks.first
  orig_cache_key = bookmark.cache_key
  Kernel::sleep 1
  visit edit_bookmark_path(bookmark)
  visit bookmark_path(bookmark)
  bookmark.reload
  assert orig_cache_key == bookmark.cache_key, "Cache key #{orig_cache_key} does not match #{bookmark.cache_key}."
end
