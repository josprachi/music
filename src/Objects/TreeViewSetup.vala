using Gee;
using Gtk;

public class BeatBox.TreeViewSetup : GLib.Object {
	public static const int COLUMN_COUNT = 17;
	
	public MusicTreeView.Hint hint;
	private string _sort_column; // Artist, Album
	private Gtk.SortType _sort_direction; // ASCENDING, DESCENDING
	private LinkedList<TreeViewColumn> _columns;
	
	public TreeViewSetup(string sort_col, SortType sort_dir, MusicTreeView.Hint hint) {
		this.hint = hint;
		_sort_column = sort_col;
		_sort_direction = sort_dir;
		
		_columns = new LinkedList<TreeViewColumn>();
		
		/* initial column state */
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "id", 
										"fixed_width", 10,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", " ", 
										"fixed_width", 24,
										"visible", true));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "#", 
										"fixed_width", 40,
										"visible", (hint == MusicTreeView.Hint.QUEUE || hint == MusicTreeView.Hint.HISTORY || hint == MusicTreeView.Hint.PLAYLIST)));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Track", 
										"fixed_width", 60,
										"visible", (hint == MusicTreeView.Hint.MUSIC || hint == MusicTreeView.Hint.SMART_PLAYLIST)));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Title", 
										"fixed_width", 220,
										"visible", true));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Length", 
										"fixed_width", 75,
										"visible", true));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Artist", 
										"fixed_width", 110,
										"visible", true));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Album", 
										"fixed_width", 200,
										"visible", true));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Genre", 
										"fixed_width", 70,
										"visible", true));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Year", 
										"fixed_width", 30,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Bitrate", 
										"fixed_width", 20,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Rating", 
										"fixed_width", 90,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Plays", 
										"fixed_width", 20,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Skips", 
										"fixed_width", 20,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Date Added", 
										"fixed_width", 70,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "Last Played", 
										"fixed_width", 70,
										"visible", false));
		_columns.add((TreeViewColumn)GLib.Object.new(typeof(TreeViewColumn), 
										"title", "BPM", 
										"fixed_width", 30,
										"visible", false));
		
		
		for(int index = 0; index < _columns.size; ++index) {
			if(_columns.get(index).title != " " && _columns.get(index).title != "Rating") {
				CellRendererText crtext = new CellRendererText();
				_columns.get(index).pack_start(crtext, true);
				_columns.get(index).set_attributes(crtext, "text", index);
			}
			else
				_columns.get(index).pack_start(new CellRendererPixbuf(), false);
				
			
			_columns.get(index).resizable = true;
			_columns.get(index).reorderable = true;
			_columns.get(index).clickable = true;
			_columns.get(index).sort_column_id = index;
			_columns.get(index).set_sort_indicator(false);
			_columns.get(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
		}
	}
	
	public string sort_column {
		get { return _sort_column; }
		set { _sort_column = value; }
	}
	
	public SortType sort_direction {
		get { return _sort_direction; }
		set { _sort_direction = value; }
	}
	
	public string sort_direction_to_string() {
		if(_sort_direction == SortType.ASCENDING)
			return "ASCENDING";
		else
			return "DESCENDING";
	}
	
	public void set_sort_direction_from_string(string dir) {
		if(dir == "ASCENDING")
			_sort_direction = SortType.ASCENDING;
		else
			_sort_direction = SortType.DESCENDING;
	}
	
	public LinkedList<TreeViewColumn> get_columns() {
		return _columns;
	}
	
	public void set_columns(LinkedList<TreeViewColumn> cols) {
		_columns = cols;
	}
	
	public void import_columns(string cols) {
		string[] col_strings = cols.split("<column_seperator>", 0);
		stdout.printf("Found %d columns\n", col_strings.length);
		
		if(col_strings.length == COLUMN_COUNT + 1) { /* the '+1' because col_strings has blank column at end */
			_columns.clear();
		}
		else {
			stdout.printf("Unsuccessful column data import. Falling back to default.\n");
			return;
		}
		
		int index;
		for(index = 0; index < col_strings.length - 1; ++index) { /* the '-1' because col_strings has blank column at end */
			string[] pieces_of_column = col_strings[index].split("<value_seperator>", 0);
			
			TreeViewColumn tvc;
			if(pieces_of_column[0] != " " && pieces_of_column[0] != "Rating")
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererText(), "text", index, null);
			else
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
			
			tvc.resizable = true;
			tvc.reorderable = true;
			tvc.clickable = true;
			tvc.sort_column_id = index;
			tvc.set_sort_indicator(false);
			tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
			
			tvc.fixed_width = int.parse(pieces_of_column[1]);
			tvc.visible = (int.parse(pieces_of_column[2]) == 1);
			
			_columns.add(tvc);
		}
	}
	
	public string columns_to_string() {
		string rv = "";
		
		foreach(TreeViewColumn tvc in _columns) {
			rv += tvc.title + "<value_seperator>" + tvc.fixed_width.to_string() + "<value_seperator>" + ( (tvc.visible) ? "1" : "0" ) + "<column_seperator>";
		}
		
		return rv;
	}
}
