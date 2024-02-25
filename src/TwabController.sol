// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum EventType {
    Deposit,
    Withdraw
}

struct Event {
    EventType eventType;
    uint256 timestamp;
    uint256 cumulativeShares;
    uint256 balances;
}

contract TwabController {
    mapping(address => Event[]) public events;

    function getEvents(address owner) public view returns (Event[] memory) {
        return events[owner];
    }

    function getIndexOfEvents_TimeStampNotGreater(address owner, uint256 timeStamp) public view returns (int256) {
        require(events[owner].length > 0, "MyVault: no events for owner");
        int256 lo = -1;
        int256 hi = int256(events[owner].length);
        while (hi - lo > 1) {
            int256 mid = (hi + lo) / 2;
            if (events[owner][uint256(mid)].timestamp <= timeStamp) {
                lo = mid;
            } else {
                hi = mid;
            }
        }
        return lo;
    }

    function getSharesInRanges(address owner, uint256 startTimeStamp, uint256 endTimeStamp)
        public
        view
        returns (uint256)
    {
        require(events[owner].length > 0, "MyVault: no events for owner");
        int256 index = int256(getIndexOfEvents_TimeStampNotGreater(owner, endTimeStamp));
        if (index == -1) {
            return 0;
        }
        uint256 cumulativeSharesEnd = events[owner][uint256(index)].cumulativeShares
            + events[owner][uint256(index)].balances * (endTimeStamp - events[owner][uint256(index)].timestamp);

        index = int256(getIndexOfEvents_TimeStampNotGreater(owner, startTimeStamp));
        uint256 cumulativeSharesStart;
        if (index == -1) {
            cumulativeSharesStart = 0;
        } else {
            cumulativeSharesStart = events[owner][uint256(index)].cumulativeShares
                + events[owner][uint256(index)].balances * (startTimeStamp - events[owner][uint256(index)].timestamp);
        }
        return cumulativeSharesEnd - cumulativeSharesStart;
    }

    function addDepositEvent(address owner, uint256 balances) public {
        if (events[owner].length == 0) {
            events[owner].push(
                Event({
                    eventType: EventType.Deposit,
                    timestamp: block.timestamp,
                    cumulativeShares: 0,
                    balances: balances
                })
            );
        } else {
            Event memory lastEvent = events[owner][events[owner].length - 1];
            uint256 timestamp = block.timestamp;
            events[owner].push(
                Event({
                    eventType: EventType.Deposit,
                    timestamp: timestamp,
                    cumulativeShares: lastEvent.cumulativeShares + lastEvent.balances * (timestamp - lastEvent.timestamp),
                    balances: balances
                })
            );
        }
    }

    function addWithdrawEvent(address owner, uint256 balances) public {
        Event memory lastEvent = events[owner][events[owner].length - 1];
        events[owner].push(
            Event({
                eventType: EventType.Withdraw,
                timestamp: block.timestamp,
                cumulativeShares: lastEvent.cumulativeShares + lastEvent.balances * (block.timestamp - lastEvent.timestamp),
                balances: balances
            })
        );
    }
}