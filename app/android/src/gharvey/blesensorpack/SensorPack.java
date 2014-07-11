package gharvey.blesensorpack;

public class SensorPack {
	public static final String LABEL_SENSOR_TEMP = "Temp";
	public static final String LABEL_SENSOR_HUMIDITY = "Humidity";
	public static final String LABEL_SENSOR_PRESSURE = "Pressure";
	public static final String LABEL_SENSOR_VISLIGHT = "Visible Light";
	public static final String LABEL_SENSOR_IRLIGHT = "IR Light";
	public static final String LABEL_SENSOR_UVINDEX = "UV Index";
	
	public static final String UNITS_TEMP = (char) 0x00B0 + "C"; // degrees C
	public static final String UNITS_HUMIDITY = "%";
	public static final String UNITS_PRESSURE = "mbar"; // millibar
	public static final String UNITS_VISLIGHT = ""; // dimensionless, relative value
	public static final String UNITS_IRLIGHT = ""; // dimensionless, relative value
	public static final String UNITS_UVINDEX = ""; // dimensionless, relative value
	
	public Sensor sensorTemp;
	public Sensor sensorHumidity;
	public Sensor sensorPressure;
	public Sensor sensorVisLight;
	public Sensor sensorIrLight;
	public Sensor sensorUvLight;
	
	public SensorPack() {
		sensorTemp = new Sensor(LABEL_SENSOR_TEMP, UNITS_TEMP);
		sensorHumidity = new Sensor(LABEL_SENSOR_HUMIDITY, UNITS_HUMIDITY);
		sensorPressure = new Sensor(LABEL_SENSOR_PRESSURE, UNITS_PRESSURE);
		sensorVisLight = new Sensor(LABEL_SENSOR_VISLIGHT, UNITS_VISLIGHT);
		sensorIrLight = new Sensor(LABEL_SENSOR_IRLIGHT, UNITS_IRLIGHT);
		sensorUvLight = new Sensor(LABEL_SENSOR_UVINDEX, UNITS_UVINDEX);
	}

	public class Sensor {
		public String name;
		public float value;
		public String units;
		
		public Sensor(String name, String units) {
			this.name = name;
			this.units = units;
		}
	}
}