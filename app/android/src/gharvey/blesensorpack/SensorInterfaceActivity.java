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

import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.NavUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

public class SensorInterfaceActivity extends Activity {

	public static UUID UART_UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID TX_UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID RX_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID CLIENT_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

	public static final String LABEL_DEVICE_NAME = "BLE_DEVICE_NAME";
	public static final String LABEL_DEVICE_ADDR = "BLE_DEVICE_ADDRESS";
	
	// define labels for the sensors on the sensor pack
	public static final String LABEL_SENSOR_TEMP = "Temperature";
	public static final String LABEL_SENSOR_HUMIDITY = "Humidity";
	public static final String LABEL_SENSOR_HEAT_INDEX = "Heat Index";
	public static final String LABEL_SENSOR_PRESSURE = "Pressure";
	public static final String LABEL_SENSOR_VISLIGHT = "Visible Light";
	public static final String LABEL_SENSOR_IRLIGHT = "IR Light";
	public static final String LABEL_SENSOR_UVINDEX = "UV Index";
	
	// define unit strings to use for each sensor
	public static final String UNITS_TEMP = (char) 0x00B0 + "F"; // degrees F
	public static final String UNITS_HUMIDITY = " %";
	public static final String UNITS_HEAT_INDEX = (char) 0x00B0 + "F"; // degrees F
	public static final String UNITS_PRESSURE = " atm"; // atmospheres
	public static final String UNITS_VISLIGHT = ""; // dimensionless, relative value
	public static final String UNITS_IRLIGHT = ""; // dimensionless, relative value
	public static final String UNITS_UVINDEX = ""; // dimensionless, relative value
	
	// define request bits for use with the Arduino code
	public static final int ID_BIT_TEMP = 6;
	public static final int ID_BIT_HUMIDITY = 5;
	public static final int ID_BIT_HEAT_INDEX = 4;
	public static final int ID_BIT_PRESSURE = 3;
	public static final int ID_BIT_VISLIGHT = 2;
	public static final int ID_BIT_IRLIGHT = 1;
	public static final int ID_BIT_UVINDEX = 0;
	
	// declare Bluetooth LE parts
	private BluetoothAdapter btAdapter;
	private BluetoothDevice bleDevice;
	private BluetoothGatt bleGatt;
	private BluetoothGattCharacteristic bleTx;
	private BluetoothGattCharacteristic bleRx;
	
	private String bleDevAddr;

	protected static final int NUM_SENSORS = 7;
	private Sensor sensorPack[] = new Sensor[NUM_SENSORS];
	private DisplayAdapter displayAdapter;
	private ListView listView;
			
	private BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
		@Override
		public void onConnectionStateChange(BluetoothGatt bleGatt, int status, int newState) {
			super.onConnectionStateChange(bleGatt, status, newState);

			TextView connectionStateView = (TextView) findViewById(R.id.connection_state);
			
			if(newState == BluetoothGatt.STATE_CONNECTED) {
				// inform the user of the connection
				//shortToast(R.string.connected_prefix + bleDevice.getName());
				connectionStateView.setText(getString(R.string.connected_prefix) + bleDevice.getName());
				Log.i("SensorInterfaceActivity", "Connected to GATT server");
				
				if(!bleGatt.discoverServices()) {
					shortToast(R.string.error_no_services);
					Log.e("SensorInterfaceActivity", "No services discovered");
				}
			} else if(newState == BluetoothGatt.STATE_DISCONNECTED) {
				//shortToast(R.string.disconnected);
				connectionStateView.setText("Disconnected");
				Log.d("SensorInterfaceActivity", "Disconnected");
			} else {
				//shortToast(R.string.state_change_prefix + newState);
				connectionStateView.setText("Unknown connection state");
				Log.e("SensorInterfaceActivity", "Unknown state: " + newState);
			}
		}
	
		@Override
		public void onServicesDiscovered(BluetoothGatt bleGatt, int status) {
			super.onServicesDiscovered(bleGatt, status);
			
			if(status != BluetoothGatt.GATT_SUCCESS) {
				Log.e("SensorInterfaceActivity", "Failure: service discovery");
			}
			
			// get characteristics
			bleTx = bleGatt.getService(UART_UUID).getCharacteristic(TX_UUID);
			bleRx = bleGatt.getService(UART_UUID).getCharacteristic(RX_UUID);
			
			// enable notifications for RX characteristic
			if(!bleGatt.setCharacteristicNotification(bleRx, true)) {
				Log.e("SensorInterfaceActivity", "Can't set RX characteristic notifications");
			}
			BluetoothGattDescriptor bleGattDesc = bleRx.getDescriptor(CLIENT_UUID);
			if(bleGattDesc != null) {
				bleGattDesc.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
				if(!bleGatt.writeDescriptor(bleGattDesc)) {
					Log.e("SensorInterfaceActivity", "Can't write RX descriptor value");
				}
			} else {
				Log.e("SensorInterfaceActivity", "Can't get RX descriptor");
			}
		}
		
		// called when data is received over Bluetooth LE
		@Override
		public void onCharacteristicChanged(BluetoothGatt bleGatt,
							BluetoothGattCharacteristic bleCharacteristic) {
			super.onCharacteristicChanged(bleGatt, bleCharacteristic);
			Log.d("SensorInterfaceActivity", "Received data");
			
			float data;
			byte[] RxBuf = bleCharacteristic.getValue();
			
			int RxBufIndex = 0;
			while(RxBufIndex < RxBuf.length) {
				// update sensor value
				for(Sensor sensor : sensorPack) {
					if(((int) RxBuf[RxBufIndex]) == sensor.id_bit) {
						// this sensor just sent data, so it must be on
						sensor.turnOn(); // verify that the sensor is on
						int bits = ((RxBuf[RxBufIndex + 1] & 0xFF)) |
								   ((RxBuf[RxBufIndex + 2] & 0xFF) << 8) |
								   ((RxBuf[RxBufIndex + 3] & 0xFF) << 16) |
								   ((RxBuf[RxBufIndex + 4] & 0xFF) << 24);
						data = Float.intBitsToFloat(bits);
						sensor.setData(data);
						break;
					}
				}
				RxBufIndex += 5; // 1 byte for sensor id + 4 bytes for sensor data
			}
			
			// update UI
			updateUI();
		}
		
		// called when write is performed to characteristic
		@Override
		public void onCharacteristicWrite(BluetoothGatt bleGatt,
				BluetoothGattCharacteristic bleCharacteristic, int status) {
			Log.d("SensorInterfaceActivity", "Characteristic write");
			if(bleGatt == null) {
				Log.e("SensorInterfaceActivity", "bleGatt is null");
			}
			if(status != BluetoothGatt.GATT_SUCCESS) {
				Log.w("SensorInterfaceActivity", "Write unsuccessful");
			}
		}
	};
	
	private void sensorPack_init() {
		sensorPack[0] = new Sensor(LABEL_SENSOR_TEMP, UNITS_TEMP, ID_BIT_TEMP);
		sensorPack[1] = new Sensor(LABEL_SENSOR_HUMIDITY, UNITS_HUMIDITY, ID_BIT_HUMIDITY);
		sensorPack[2] = new Sensor(LABEL_SENSOR_HEAT_INDEX, UNITS_HEAT_INDEX, ID_BIT_HEAT_INDEX);
		sensorPack[3] = new Sensor(LABEL_SENSOR_PRESSURE, UNITS_PRESSURE, ID_BIT_PRESSURE);
		sensorPack[4] = new Sensor(LABEL_SENSOR_VISLIGHT, UNITS_VISLIGHT, ID_BIT_VISLIGHT);
		sensorPack[5] = new Sensor(LABEL_SENSOR_IRLIGHT, UNITS_IRLIGHT, ID_BIT_IRLIGHT);
		sensorPack[6] = new Sensor(LABEL_SENSOR_UVINDEX, UNITS_UVINDEX, ID_BIT_UVINDEX);
	}
	
	public void display_init() {
		// initialize user interface
		displayAdapter = new DisplayAdapter(this, sensorPack);
		listView = (ListView) findViewById(R.id.listView);
		
		// set up header
		LayoutInflater inflater = getLayoutInflater();
		View header = inflater.inflate(R.layout.sensor_header, null);
		listView.addHeaderView(header, null, false);
		listView.setAdapter(displayAdapter);
		
		listView.setOnItemClickListener(new OnItemClickListener() {
			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
				Log.d("SensorInterfaceActivity", "User clicked list item");
				if(view == null) {
					view = (ListView) displayAdapter.getView(position, view, parent);
				}
				
				Sensor clickedSensor = (Sensor) listView.getItemAtPosition(position);
				Log.v("SensorInterfaceActivity", "Toggling sensor state");
				clickedSensor.toggle();

				sendSensorPackState();
				updateUI();
			}
		});
	}
	
	public void sendSensorPackState() {
		// send data over Bluetooth LE
		Log.v("SensorInterfaceActivity", "Constructing byte to send");
		if(bleTx == null) {
			Log.e("SensorInterfaceActivity", "No Tx characteristic");
			return;
		}

		byte[] txByte = {0};
		for(Sensor sensor : sensorPack) {
			if(sensor.isOn()) {
				txByte[0] |= (byte) (0x1 << sensor.id_bit);
			}
		}
		
		// update TX characteristic
		Log.v("SensorInterfaceActivity", "Setting Tx value: 0x" + Integer.toHexString((int) txByte[0]));
		bleTx.setValue(txByte);
		
		// send byte
		Log.v("SensorInterfaceActivity", "Sending the data");
		if(bleGatt.writeCharacteristic(bleTx)) {
			Log.i("SensorInterfaceActivity", "Sensor request byte sent");
		} else {
			Log.e("SensorInterfaceActivity", "Couldn't send request byte");
		}
	}
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_sensor_interface);
		
		sensorPack_init();
		display_init();

		// get the intent used to start this activity
		final Intent incoming_i = getIntent();
		bleDevAddr = incoming_i.getStringExtra(LABEL_DEVICE_ADDR);
		
		// initialize Bluetooth LE communications
		btAdapter = BluetoothAdapter.getDefaultAdapter();

		Log.d("SensorInterfaceActivity", "Getting device at address " + bleDevAddr);
		bleDevice = btAdapter.getRemoteDevice(bleDevAddr);
		bleGatt = bleDevice.connectGatt(this, false, gattCallback);
	}
	
	public void updateUI() {
		runOnUiThread(new Runnable() {
			public void run() {
				displayAdapter.notifyDataSetChanged();
			}
		});
	}
	
	public void allSensorsOn(View view) {
		for(Sensor s : sensorPack) {
			s.turnOn();
		}
		sendSensorPackState();
		updateUI();
	}
	
	public void allSensorsOff(View view) {
		for(Sensor s : sensorPack) {
			s.turnOff();
		}
		sendSensorPackState();
		updateUI();
	}
	
	@Override
	public void onPause() {
		super.onPause();
		closeActivity();
	}

	@Override
	public void onStop() {
		super.onStop();
		closeActivity();
	}
	
	public void closeActivity() {
		bleDisconnect();
	}
	
	public void bleDisconnect(View view) {
		bleDisconnect();
	}
	
	public void bleDisconnect() {
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
		switch (item.getItemId()) {
	    // Respond to the action bar's Up/Home button
	    case android.R.id.home:
	    	Log.d("SensorInterfaceActivity", "User pressed 'Up'");
	    	bleDisconnect();
	        NavUtils.navigateUpFromSameTask(this);
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
