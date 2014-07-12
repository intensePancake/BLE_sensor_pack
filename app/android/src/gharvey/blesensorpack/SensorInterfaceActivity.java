/*
 * Sensor interface activity for the BLE Sensor App
 * This activity creates an interface between the sensor data obtained
 * through Bluetooth LE and the user.  It communicates with the BLE
 * Sensor Pack through the BleService.
 *
 * Author: Graham Harvey
 * Last modified: 9 July 2014
 *
 * Parts of this code are similar to the sample BluetoothLeGatt code on
 * the Android developer website.  The reference material that was used
 * is included in the project directory at doc/ref/BLE/Android.
 * 
 */

package gharvey.blesensorpack;

import java.util.ArrayList;
import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.Toast;

public class SensorInterfaceActivity extends Activity {
	
	public static UUID UART_UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID TX_UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID RX_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID CLIENT_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
	
	public static final String LABEL_DEVICE_NAME = "BLE_DEVICE_NAME";
	public static final String LABEL_DEVICE_ADDR = "BLE_DEVICE_ADDRESS";
	
	// define labels for the sensors on the sensor pack
	public static final String LABEL_SENSOR_TEMP = "Temp";
	public static final String LABEL_SENSOR_HUMIDITY = "Humidity";
	public static final String LABEL_SENSOR_PRESSURE = "Pressure";
	public static final String LABEL_SENSOR_VISLIGHT = "Visible Light";
	public static final String LABEL_SENSOR_IRLIGHT = "IR Light";
	public static final String LABEL_SENSOR_UVINDEX = "UV Index";
	
	// define unit strings to use for each sensor
	public static final String UNITS_TEMP = (char) 0x00B0 + "C"; // degrees C
	public static final String UNITS_HUMIDITY = "%";
	public static final String UNITS_PRESSURE = "atm"; // atmospheres
	public static final String UNITS_VISLIGHT = ""; // dimensionless, relative value
	public static final String UNITS_IRLIGHT = ""; // dimensionless, relative value
	public static final String UNITS_UVINDEX = ""; // dimensionless, relative value
	
	// define request bits for use with the Arduino code
	public static final int REQUEST_BIT_TEMP = 5;
	public static final int REQUEST_BIT_HUMIDITY = 4;
	public static final int REQUEST_BIT_PRESSURE = 3;
	public static final int REQUEST_BIT_VISLIGHT = 2;
	public static final int REQUEST_BIT_IRLIGHT = 1;
	public static final int REQUEST_BIT_UVINDEX = 0;
	
	// define indices for the ArrayList of sensors.
	// this is done for clarity
	public static final int INDEX_TEMP = 5;
	public static final int INDEX_HUMIDITY = 4;
	public static final int INDEX_PRESSURE = 3;
	public static final int INDEX_VISLIGHT = 2;
	public static final int INDEX_IRLIGHT = 1;
	public static final int INDEX_UVINDEX = 0;
	
	// declare Bluetooth LE parts
	private BluetoothDevice bleDevice;
	private BluetoothGatt bleGatt;
	private BluetoothGattCharacteristic bleTx;
	private BluetoothGattCharacteristic bleRx;
	
	private String bleDevAddr;
	
	private DisplayAdapter displayAdapter;
	private ListView listView;
	private ArrayList<Sensor> sensorPack;
			
	private BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
		@Override
		public void onConnectionStateChange(BluetoothGatt bleGatt, int status, int newState) {
			super.onConnectionStateChange(bleGatt, status, newState);
			if(newState == BluetoothGatt.STATE_CONNECTED) {
				// inform the user of the connection
				shortToast(R.string.connected_prefix + bleDevice.getName());
				
				if(!bleGatt.discoverServices()) {
					shortToast(R.string.error_no_services);
				}
				
			} else if(newState == BluetoothGatt.STATE_DISCONNECTED) {
				shortToast(R.string.disconnected);
			} else {
				shortToast(R.string.state_change_prefix + newState);
				Log.e("onConnectionStateChange()", "Unknown state: " + newState);
			}
		}
	
		@Override
		public void onServicesDiscovered(BluetoothGatt bleGatt, int status) {
			super.onServicesDiscovered(bleGatt, status);
			if(status != BluetoothGatt.GATT_SUCCESS) {
				Log.e("onServicesDiscovered()", "Failure: service discovery");
			}
			
			// get characteristics
			bleTx = bleGatt.getService(UART_UUID).getCharacteristic(TX_UUID);
			bleRx = bleGatt.getService(UART_UUID).getCharacteristic(RX_UUID);
			
			// enable notifications for RX characteristic
			if(!bleGatt.setCharacteristicNotification(bleRx, true)) {
				Log.e("onServicesDiscovered()", "Can't set RX characteristic notifications");
			}
			BluetoothGattDescriptor bleGattDesc = bleRx.getDescriptor(CLIENT_UUID);
			if(bleGattDesc != null) {
				bleGattDesc.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
				if(!bleGatt.writeDescriptor(bleGattDesc)) {
					Log.e("onServicesDiscovered()", "Can't write RX descriptor value");
				}
			} else {
				Log.e("onServicesDiscovered()", "Can't get RX descriptor");
			}
		}
		
		@Override
		public void onCharacteristicChanged(BluetoothGatt bleGatt,
							BluetoothGattCharacteristic bleCharacteristic) {
			super.onCharacteristicChanged(bleGatt, bleCharacteristic);
			
			Log.d("onCharacteristicChanged()", "Received data");
			float data;
			byte[] RxBuf = bleCharacteristic.getValue();
			int RxBufIndex = 0;
			while(RxBufIndex < RxBuf.length) {
				int dataOffset = RxBufIndex + 1;
				switch(RxBuf[RxBufIndex]) {
				case REQUEST_BIT_TEMP:
					// the next 4 bytes are temperature data
					data = bleCharacteristic.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
																 dataOffset);
					sensorPack.get(INDEX_TEMP).setData(data);
					break;
				case REQUEST_BIT_HUMIDITY:
					// the next 4 bytes are humidity data
					data = bleCharacteristic.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
																	 dataOffset);
					sensorPack.get(INDEX_HUMIDITY).setData(data);
					break;
				case REQUEST_BIT_PRESSURE:
					// the next 4 bytes are pressure data
					data = bleCharacteristic.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
																	 dataOffset);
					sensorPack.get(INDEX_PRESSURE).setData(data);
					break;
				case REQUEST_BIT_VISLIGHT:
					// the next 4 bytes are visible light data
					data = bleCharacteristic.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
																	 dataOffset);
					sensorPack.get(INDEX_VISLIGHT).setData(data);
					break;
				case REQUEST_BIT_IRLIGHT:
					// the next 4 bytes are IR light data
					data = bleCharacteristic.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
																	dataOffset);
					sensorPack.get(INDEX_IRLIGHT).setData(data);
					break;
				case REQUEST_BIT_UVINDEX:
					// the next 4 bytes are UV index data
					data = bleCharacteristic.getFloatValue(BluetoothGattCharacteristic.FORMAT_FLOAT,
																	dataOffset);
					sensorPack.get(INDEX_UVINDEX).setData(data);
					break;
				default:
					Log.e("onCharacteristicChanged()", "No sensor identifier read");
					break;
				}
				
				RxBufIndex += 5; // 1 byte for sensor identifier + 4 bytes for sensor data
			}
			
			// update UI
			displayAdapter.notifyDataSetChanged();
		}
	};
	
	private void sensorPack_init() {
		Sensor temp = new Sensor(LABEL_SENSOR_TEMP, UNITS_TEMP, REQUEST_BIT_TEMP);
		Sensor humidity = new Sensor(LABEL_SENSOR_HUMIDITY, UNITS_HUMIDITY, REQUEST_BIT_HUMIDITY);
		Sensor pressure = new Sensor(LABEL_SENSOR_PRESSURE, UNITS_PRESSURE, REQUEST_BIT_PRESSURE);
		Sensor visLight = new Sensor(LABEL_SENSOR_VISLIGHT, UNITS_VISLIGHT, REQUEST_BIT_VISLIGHT);
		Sensor irLight = new Sensor(LABEL_SENSOR_IRLIGHT, UNITS_IRLIGHT, REQUEST_BIT_IRLIGHT);
		Sensor uvIndex = new Sensor(LABEL_SENSOR_UVINDEX, UNITS_UVINDEX, REQUEST_BIT_UVINDEX);

		sensorPack = new ArrayList<Sensor>();
		sensorPack.add(temp);
		sensorPack.add(humidity);
		sensorPack.add(pressure);
		sensorPack.add(visLight);
		sensorPack.add(irLight);
		sensorPack.add(uvIndex);
	}
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_sensor_interface);
		
		sensorPack_init();
		
		// initialize user interface
		listView = (ListView) findViewById(R.id.listview);
		displayAdapter = new DisplayAdapter(this, sensorPack);
		listView.setAdapter(displayAdapter);
		listView.setOnItemClickListener(new OnItemClickListener() {
			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position,
					long id) {
				if(view == null) {
					view = (ListView) displayAdapter.getView(position, view, parent);
				}
				ListView lv = (ListView) view;
				
				Sensor sensor = (Sensor) lv.getItemAtPosition(position);
				Log.d("onItemClick()", "Clicked item at position " + position);
				Log.d("onItemClick()", "Function id = " + id);
				Log.d("onItemClick()", "Object id = " + sensor.id);
				Log.d("onItemClick()", "Sensor name = " + sensor.getName());
			}
		});
				
		// get the intent used to start this activity
		final Intent incoming_i = getIntent();
		bleDevAddr = incoming_i.getStringExtra(LABEL_DEVICE_ADDR);
		
		final BluetoothManager btManager =
				(BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
		final BluetoothAdapter btAdapter = btManager.getAdapter();
				
		bleDevice = btAdapter.getRemoteDevice(bleDevAddr);
		bleDevice.connectGatt(this, false, gattCallback);
	}
	
	@Override
	public void onStop() {
		super.onStop();
		if(bleGatt != null) {
			bleGatt.disconnect();
			bleGatt.close();
			bleGatt = null;
			bleTx = null;
			bleRx = null;
		}
		finish();
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.sensor_interface, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle action bar item clicks here. The action bar will
		// automatically handle clicks on the Home/Up button, so long
		// as you specify a parent activity in AndroidManifest.xml.
		int id = item.getItemId();
		if (id == R.id.action_settings) {
			return true;
		}
		return super.onOptionsItemSelected(item);
	}
	
	public void shortToast(int resId) {
		Toast.makeText(this, getString(resId), Toast.LENGTH_SHORT).show();
	}
	
	public void shortToast(CharSequence text) {
		Toast.makeText(this, text, Toast.LENGTH_SHORT).show();
	}
}
