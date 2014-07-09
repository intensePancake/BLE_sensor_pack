using BLEServiceBrowser.Model;
using BLEServiceBrowser.Utils;
using BLEServiceBrowser.Viewmodel;
using Windows.Devices.Enumeration;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;

namespace BLEServiceBrowser
{
    public sealed partial class MainPage : Page
    {
        // private reference to the Main viewmodel
        private MainViewModel viewmodel;

        public MainPage()
        {
            this.InitializeComponent();

            // Set the reference to the current datacontext as this would have already been initialised.
            this.viewmodel = this.DataContext as MainViewModel;
        }

        // Handle selection changed event from the combo box 
        private void DeviceSelector_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            DeviceInformation selected = this.possibleDevicesList.SelectedItem as DeviceInformation;

            if (selected != null)
            {
                // Send reference of selected item to the viewmodel to be processed.
                this.viewmodel.GetSelectedProfile(selected);
            }
        }

        // Handle the changed event of the supported device types.
        private void SupportedTypesList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            NamedGuid selected = this.DeviceSelector.SelectedItem as NamedGuid;
            if (selected != null)
            {
                // Send reference of selected item to the viewmodel to be processed.
                this.viewmodel.SetSelectedDevice(selected);
            }
            else
            {
                MessageHelper.DisplayBasicMessage(StringResources.DeviceUnAvailable);
            }

        }

        // Handle the button pressed event, this calls the viewmodel to scan for devices.
        private void ScanButton_Click(object sender, RoutedEventArgs e)
        {
            this.viewmodel.GetPossibleDevices();
        }

        // Handle the user selecting a service
        private void ServiceList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            NamedGuid selected = this.possibleServiceList.SelectedItem as NamedGuid;

            if (selected != null)
            {
                // Send reference of selected item to the viewmodel to be processed.
                this.viewmodel.HandleSelectedService(selected);
            }
        }

        // Handle the user selecting a characteristic
        private void CharacteristicsList_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            int index = this.possibleCharacteristicsList.SelectedIndex;

            if (index >= 0)
            {
                // Send index value of selected item to the viewmodel to be processed.
                viewmodel.HandleSelectedCharacteristic(index);
            }
        }

        // Handle the button pressed event, for a read function from the device.
        private void ReadButton_Click(object sender, RoutedEventArgs e)
        {
            viewmodel.HandleReadCharateristic();
        }

        // Handle the button pressed event, for a write function to the device, sending the value of a text box as a string parameter.
        private void WriteButton_Click(object sender, RoutedEventArgs e)
        {
            // get the string value from a text box
            string input = this.textbox.Text;
            // If the text box has a vlaue, perform the function, otherwise display a message box telling user the text box needs a value.
            if (!string.IsNullOrEmpty(input))
            {
                viewmodel.HandleWriteCharateristic(input);
            }
            else
            {
                MessageHelper.DisplayBasicMessage(StringResources.EmptyStringError);
            }
        }

        // Handel notification toggle changed event, and pass to the viewmodel to be processed
        private void Notification_Toggled(object sender, RoutedEventArgs e)
        {
            this.viewmodel.HandleNotificationCharateristic(this.notoficationToggle.IsOn);
        }

        // Handel indicate toggle changed event, and pass to the viewmodel to be processed
        private void ToggleSwitch_Toggled(object sender, RoutedEventArgs e)
        {
            this.viewmodel.HandleIndicateCharateristic(this.notoficationToggle.IsOn);
        }
    }
}
