# ShieldCombineTest
Test coexisting shields - specific + all-except

How to Reproduce Your Bug

Request Authorization first
Pick an app for Store A - this simulates a time limit block
Pick a DIFFERENT app for Store B - this simulates a downtime all-except
Click "Apply Both Shields"
Expected: Store B should be accessible -> all exept
Actual: All apps are blocked

What to Look For
If Store B (exemption) becomes blocked when Store A (specific) is shielded, this may suggest the Apple framework limitation or bug.
