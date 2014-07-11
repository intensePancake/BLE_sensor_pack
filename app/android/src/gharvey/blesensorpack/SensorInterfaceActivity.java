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
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.TextView;
import android.widget.Toast;

public class SensorInterfaceActivity extends Activity {
	
	public static UUID UART_UUID = UUID.fromString("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID TX_UUID = UUID.fromString("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID RX_UUID = UUID.fromString("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");
    public static UUID CLIENT_UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
	
	public static final String LABEL_DEVICE_NAME = "BLE_DEVICE_NAME";
	public static final String LABEL_DEVICE_ADDR = "BLE_DEVICE_ADDRESS";
	
	private String bleDevName;
	private String bleDevAddr;
	
	private BluetoothDevice bleDevice;
	private BluetoothGatt bleGatt;
	private BluetoothGattCharacteristic bleTx;
	private BluetoothGattCharacteristic bleRx;
	
	private TextView dbg_msg;
		
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
				
				dbg_msg.append(getString(R.string.connected_prefix) + bleDevice.getName());
			} else if(newState == BluetoothGatt.STATE_DISCONNECTED) {
				shortToast(R.string.disconnected);
			} else {
				shortToast(R.string.state_change_prefix + newState);
			}
		}
	
		@Override
		public void onServicesDiscovered(BluetoothGatt bleGatt, int status) {
			super.onServicesDiscovered(bleGatt, status);
			if(status != BluetoothGatt.GATT_SUCCESS) {
				dbg_msg.append(getString(R.string.error_service_discovery) + status + "\n");
			}
			
			// get characteristics
			bleTx = bleGatt.getService(UART_UUID).getCharacteristic(TX_UUID);
			bleRx = bleGatt.getService(UART_UUID).getCharacteristic(RX_UUID);
			
			// enable notifications for RX characteristic
			if(!bleGatt.setCharacteristicNotification(bleRx, true)) {
				dbg_msg.append(getString(R.string.error_rx_notifications) + "\n");
			}
			BluetoothGattDescriptor bleGattDesc = bleRx.getDescriptor(CLIENT_UUID);
			if(bleGattDesc != null) {
				bleGattDesc.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
				if(!bleGatt.writeDescriptor(bleGattDesc)) {
					dbg_msg.append(getString(R.string.error_rx_notifications) + "\n");
				} else {
					dbg_msg.append("Can't get RX client descriptor\n");
				}
			}
		}
		
		@Override
		public void onCharacteristicChanged(BluetoothGatt bleGatt,
							BluetoothGattCharacteristic bleCharacteristic) {
			super.onCharacteristicChanged(bleGatt, bleCharacteristic);
			dbg_msg.append("Received: " + bleCharacteristic.getStringValue(0));
		}
	};
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_sensor_interface);
				
		// get the intent used to start this activity
		final Intent incoming_i = getIntent();
		bleDevName = incoming_i.getStringExtra(LABEL_DEVICE_NAME);
		bleDevAddr = incoming_i.getStringExtra(LABEL_DEVICE_ADDR);
		
		final BluetoothManager btManager =
				(BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
		final BluetoothAdapter btAdapter = btManager.getAdapter();
				
		bleDevice = btAdapter.getRemoteDevice(bleDevAddr);
		bleDevice.connectGatt(this, false, gattCallback);
		
		dbg_msg = (TextView) findViewById(R.id.dbg_msg);
		dbg_msg.setText(bleDevName);
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
