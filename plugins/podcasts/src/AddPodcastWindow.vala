/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gtk;

public class BeatBox.AddPodcastWindow : Window {
	public LibraryWindow lw;
	
	VBox content;
	HBox padding;
	
	Granite.Widgets.HintedEntry _source;
	Gtk.Image _is_valid;
	Gtk.Spinner _is_working;
	Button _save;
	Button _cancel;
	
	Gdk.Pixbuf not_valid;
	Gdk.Pixbuf valid;
	
	Gee.HashSet<string> existing_rss;
	bool already_validating;
	string next;
	
	public signal void playlist_saved(Playlist p);
	
	public AddPodcastWindow(LibraryWindow lw) {
		this.lw = lw;
		already_validating = false;
		next = "";
		
		title = (_("Add Podcast"));
		
		set_size_request(400, -1);
		
		this.resizable = false;
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		content = new VBox(false, 12);
		padding = new HBox(false, 12);
		
		/* get pixbufs */
		valid = Icons.PROCESS_COMPLETED.render (IconSize.MENU);
		not_valid = Icons.PROCESS_ERROR.render (IconSize.MENU);
		
		if(valid == null)
			valid = Icons.render_icon(Gtk.Stock.YES, IconSize.MENU);
		if(not_valid == null)
			not_valid = Icons.render_icon(Gtk.Stock.NO, IconSize.MENU);
		
		/* start out by creating all category labels */
		Label sourceLabel = new Label(_("Podcast RSS Source"));
		_source = new Granite.Widgets.HintedEntry(_("Podcast Source..."));
		_is_valid = new Gtk.Image.from_pixbuf(not_valid);
		_is_working = new Gtk.Spinner();
		_save = new Button.with_label(_("Add"));
		_cancel = new Button.with_label(_("Cancel"));
		/* set up controls */
		sourceLabel.xalign = 0.0f;
		sourceLabel.set_markup("<b>%s</b>".printf(_("Podcast RSS Source")));
		
		_is_working.start();
		
		/* add controls to form */
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.set_spacing (6);
		bottomButtons.pack_start(_cancel, false, false, 0);
		bottomButtons.pack_end(_save, false, false, 0);

		/* source vbox */
		HBox sourceBox = new HBox(false, 6);
		sourceBox.pack_start(_source, true, true, 0);
		sourceBox.pack_end(_is_valid, false, false, 0);
		sourceBox.pack_end(_is_working, false, false, 0);
		
		content.pack_start(wrap_alignment(sourceLabel, 12, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(sourceBox, 0, 12, 0, 0), false, true, 0);
		content.pack_start(bottomButtons, false, false, 12);
		
		padding.pack_start(content, true, true, 12);
		
		add(padding);
		
		existing_rss = new Gee.HashSet<string>();
		foreach(int i in lw.library_manager.podcast_ids()) {
			var pod = lw.library_manager.media_from_id(i);
			existing_rss.add(pod.podcast_rss);
		}
		
		show_all();
		sourceChanged();
		
		_save.clicked.connect(saveClicked);
		_cancel.clicked.connect(cancel_clicked);
		_source.activate.connect(sourceActivate);
		_source.changed.connect(sourceChanged);
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}

	void cancel_clicked () {
		destroy ();
	}

	void saveClicked() {
		var success = lw.library_manager.pm.parse_new_rss(_source.get_text());
		
		if(success)
			this.destroy();
		else {
			lw.doAlert(_("No Podcasts Found"), _("The provided source is invalid. Make sure you are entering an RSS feed in XML format."));
		}
	}
	
	void sourceActivate() {
		saveClicked();
	}
	
	void sourceChanged() {
		string url = _source.get_text();
		
		// simple quick validation
		if(!url.has_prefix("http://") || url.contains(" ") || existing_rss.contains(url)) {
			_is_valid.set_from_pixbuf(not_valid);
			_is_valid.show();
			_is_working.hide();
			_save.set_sensitive(false);
			next = "";
		}
		else {
			_is_working.show();
			_is_valid.hide();
			
			if(already_validating) {
				next = url;
			}
			else {
				already_validating = true;
				next = url;
				
				try {
					Thread.create<void*>(test_url_validity, false);
				}
				catch(GLib.ThreadError err) {
					stdout.printf("ERROR: Could not create thread to fetch new podcasts: %s \n", err.message);
				}
			}
		}
	}
	
	public void* test_url_validity () {
		bool is_valid = false;
		while(next != "") {
			var previous_url = next;
			next = "";
			is_valid = lw.library_manager.pm.is_valid_rss(previous_url) && !existing_rss.contains(previous_url);
		}
		
		Idle.add( () => {
			_is_working.hide();
			_is_valid.show();
			if(is_valid)
				_is_valid.set_from_pixbuf(valid);
			else
				_is_valid.set_from_pixbuf(not_valid);
			
			_save.set_sensitive(is_valid);
			
			already_validating = false;
			return false;
		});
				
		return null;
	}
}