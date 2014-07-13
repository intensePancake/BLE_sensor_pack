package gharvey.blesensorpack;

import java.util.Locale;

import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;
 
public class DisplayAdapter extends ArrayAdapter<Sensor> {
	Context context;
	Sensor sensorPack[] = null;
	
	public DisplayAdapter(Context context, Sensor[] sensorPack) {
		super(context, R.layout.sensor_row, sensorPack);
		this.context = context;
		this.sensorPack = sensorPack;
	}
	
	@Override
	public Sensor getItem(int position) {
		return sensorPack[position];
	}
 
	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		View row = convertView;
		if(row == null) {
			LayoutInflater inflater = ((Activity) context).getLayoutInflater();
			row = inflater.inflate(R.layout.sensor_row, parent, false);
		}
		
		Sensor sensor = sensorPack[position];
		if(sensor != null) {
			TextView nameTextView = (TextView) row.findViewById(R.id.name);
			TextView dataTextView = (TextView) row.findViewById(R.id.data);
			TextView unitTextView = (TextView) row.findViewById(R.id.units);
			TextView stateTextView = (TextView) row.findViewById(R.id.state);
			
			nameTextView.setText(sensor.getName());
			
			String dataStr;
			if(sensor.hasData()) {
				dataStr = String.format(Locale.US, "%.2f", sensor.getData());
				
				unitTextView.setText(sensor.getUnits());
			} else {
				dataStr = "-";
			}
			dataTextView.setText(dataStr);
			
			if(sensor.isOn()) {
				stateTextView.setText(R.string.sensor_state_on);
				stateTextView.setTextColor(context.getResources().getColor(R.color.green));
			} else {
				stateTextView.setText(R.string.sensor_state_off);
				stateTextView.setTextColor(context.getResources().getColor(R.color.red));
			}
		}
		
		return row;
	}
}