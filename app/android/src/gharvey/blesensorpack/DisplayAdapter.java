package gharvey.blesensorpack;

import java.util.ArrayList;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

public class DisplayAdapter extends BaseAdapter {
	
	Context context;
	ArrayList<Sensor> sensorPack;
	private static LayoutInflater inflater;
	
	public DisplayAdapter(Context context, ArrayList<Sensor> sensorPack) {
		this.context = context;
		this.sensorPack = sensorPack;
		inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
	}

	@Override
	public int getCount() {
		return sensorPack.size();
	}

	@Override
	public Object getItem(int position) {
		return sensorPack.get(position);
	}

	@Override
	public long getItemId(int position) {
		return position;
	}

	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		View view = convertView;
		if(view == null) {
			view = inflater.inflate(R.layout.sensor_row, null);
		}
		
		TextView sensorName = (TextView) view.findViewById(R.id.sensorName);
		TextView sensorValue = (TextView) view.findViewById(R.id.sensorData);
		
		if(sensorPack.get(position).getName().contentEquals(sensorName.getText())) {
			// sensor name has changed, so update it
			sensorName.setText(sensorPack.get(position).getName());
		}
		
		// update sensor data
		sensorValue.setText(Float.toString(sensorPack.get(position).getData()));
		
		return view;
	}
}
