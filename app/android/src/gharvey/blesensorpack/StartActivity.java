/*
 * Start activity for the BLE Sensor App
 * This activity displays a Connect button for the user.
 * When it is clicked, the activity searches for BLE devices and connects
 * to the first possible match for the Adafruit nRF8001 breakout board.
 * It then starts an activity for tracking sensor data from the rest of
 * the BLE Sensor project. This app has not been tested around multiple
 * Bluetooth enabled devices.
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

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothAdapter.LeScanCallback;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;


public class StartActivity extends Activity {
	
	private BluetoothAdapter btAdapter;
	private boolean scanning;
	private Handler bleHandler;

	private static final String BLE_DEVICE_NAME = "UART";
	public static final int REQUEST_ENABLE_BT = 1;
	private static final long SCAN_TIMEOUT = 3000; // timeout in milliseconds
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_start);
                
        bleHandler = new Handler();
		
		// Initialize Bluetooth adapter
        /*
        final BluetoothManager btManager =
				(BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
		btAdapter = btManager.getAdapter();
		*/
        btAdapter = BluetoothAdapter.getDefaultAdapter();
		
		// check if Bluetooth is supported on the device
		if(btAdapter == null) {
			Toast.makeText(this, R.string.error_bt_not_supported, Toast.LENGTH_SHORT).show();
			finish();
			return;
		}
		
		// check if Bluetooth LE is supported on the device
		if(!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
			Toast.makeText(this, R.string.error_ble_not_supported, Toast.LENGTH_SHORT).show();
			finish();
		}
		
		Log.d("StartActivity", "Setup complete");
    }
	
	@Override
	protected void onResume() {
		super.onResume();
		
		ensureBtEn();
		//btAdapter.startLeScan(bleScanCallback);
		//btAdapter.startLeScan(UUIDs, bleScanCallback);
	}
	
	@Override
	protected void onPause() {
		super.onPause();
		
		// stop scanning if needed
		if(scanning) {
			scanning = false;
			btAdapter.stopLeScan(bleScanCallback);
		}
	}
	
	@Override
	protected void onActivityResult(int reqCode, int resCode, Intent data_i) {
		// user did not enable Bluetooth
		if(reqCode == REQUEST_ENABLE_BT && resCode == Activity.RESULT_CANCELED) {
			finish();
			return;
		}
		super.onActivityResult(reqCode, resCode, data_i);
	}
	
	/*
	 * ensure that Bluetooth is available and enabled, or
	 * request permission to enable it
	 */
	protected void ensureBtEn() {
		if(!btAdapter.isEnabled()) {
			Intent btEnable_i = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
			startActivityForResult(btEnable_i, REQUEST_ENABLE_BT);
		}
	}
		
	/*
	 * Scan for available BLE devices and connect to the first one.
	 * Called when the user clicks the Connect button.
	 */
	public void bleScan(View view) {
		Log.v("StartActivity", "In bleScan()");
		// set up timeout
		bleHandler.postDelayed(new Runnable() {
			@Override
			public void run() {
				if(scanning) {
					scanning = false;
					Log.v("StartActivity", "Stopping the scan");
					btAdapter.stopLeScan(bleScanCallback);
					
					// let the user know we couldn't find the device
					Toast.makeText(StartActivity.this, R.string.error_no_device, Toast.LENGTH_SHORT).show();
				}
			}
		}, SCAN_TIMEOUT);

		
		// start the scan
		scanning = true;
		Log.v("StartActivity", "Starting the scan");
		btAdapter.startLeScan(bleScanCallback);
		Log.v("StartActivity", "Leaving bleScan()");
		//btAdapter.startLeScan(UUIDs, bleScanCallback);
	}
	
	private LeScanCallback bleScanCallback =
			new LeScanCallback() {
		@Override
		public void onLeScan(final BluetoothDevice bleDevice, int rssi,
							 byte[] scanRecord) {			
			// check if the device is the sensor pack
			if(isSensorPack(bleDevice, scanRecord)) {
				Log.d("StartActivity", "Found Sensor Pack");
				if(scanning) {
					btAdapter.stopLeScan(bleScanCallback);
					scanning = false;
				}
				
				// create an intent to interface with device
				Intent sensorInterface_i = new Intent(StartActivity.this, SensorInterfaceActivity.class);
				sensorInterface_i.putExtra(SensorInterfaceActivity.LABEL_DEVICE_NAME, bleDevice.getName());
				sensorInterface_i.putExtra(SensorInterfaceActivity.LABEL_DEVICE_ADDR, bleDevice.getAddress());
				
				startActivity(sensorInterface_i);
			} else {
				Log.d("StartActivity", "Found other device");
			}
		}
	};
	
	// still need to implement this
	private boolean isSensorPack(BluetoothDevice btDevice, byte[] scanRecord) {
		if(!(btDevice.getName().contentEquals(BLE_DEVICE_NAME))) {			
			return false;
		}
		// the device name is correct
		if(parseUUIDs(scanRecord).contains(SensorInterfaceActivity.UART_UUID)) {
			// the device offers the UART service
			return true;
		}
		return false;
	}
	
	/* parseUUIDs - returns a list of custom service UUIDs for Bluetooth Low Energy
	 * 
	 * This method was taken directly from
	 * http://stackoverflow.com/questions/18019161/startlescan-with-128-bit-uuids-doesnt-work-on-native-android-ble-implementation/24539704#24539704
	 */
	private List<UUID> parseUUIDs(final byte[] advertisedData) {
		List<UUID> uuids = new ArrayList<UUID>();

		int offset = 0;
		while (offset < (advertisedData.length - 2)) {
			int len = advertisedData[offset++];
			if (len == 0)
				break;

			int type = advertisedData[offset++];
			switch (type) {
			case 0x02: // Partial list of 16-bit UUIDs
			case 0x03: // Complete list of 16-bit UUIDs
				while (len > 1) {
					int uuid16 = advertisedData[offset++];
					uuid16 += (advertisedData[offset++] << 8);
					len -= 2;
					uuids.add(UUID.fromString(String.format(
							"%08x-0000-1000-8000-00805f9b34fb", uuid16)));
				}
				break;
			case 0x06:// Partial list of 128-bit UUIDs
			case 0x07:// Complete list of 128-bit UUIDs
				// Loop through the advertised 128-bit UUID's.
				while (len >= 16) {
					try {
						// Wrap the advertised bits and order them.
						ByteBuffer buffer = ByteBuffer.wrap(advertisedData,
								offset++, 16).order(ByteOrder.LITTLE_ENDIAN);
						long mostSignificantBit = buffer.getLong();
						long leastSignificantBit = buffer.getLong();
						uuids.add(new UUID(leastSignificantBit,
								mostSignificantBit));
					} catch (IndexOutOfBoundsException e) {
						// Defensive programming.
						// Log.e(LOG_TAG, e.toString());
						continue;
					} finally {
						// Move the offset to read the next uuid.
						offset += 15;
						len -= 16;
					}
				}
				break;
			default:
				offset += (len - 1);
				break;
			}
		}
		return uuids;
	}

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.start, menu);
        return true;
    };

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        return super.onOptionsItemSelected(item);
    }
}
